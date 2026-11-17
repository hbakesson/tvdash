import Darwin
import Foundation
import OSLog
import UIKit

nonisolated private let logger = Logger(subsystem: "com.hbakesson.tvdash", category: "Metrics")

/// Reads system measurements through the Mach, sysctl and BSD socket APIs.
///
/// All of these work inside the tvOS sandbox. What tvOS does *not* allow – listing other processes or installed
/// apps – is deliberately absent; see `docs/adr/0004-system-metrics-on-tvos.md`.
struct DarwinMetricsService: SystemMetricsProviding {
    /// Captured when the service is created at app launch.
    let launchDate: Date

    init(launchDate: Date = .now) {
        self.launchDate = launchDate
    }

    func deviceInfo() -> DeviceInfo {
        let info = ProcessInfo.processInfo
        let bundle = Bundle.main
        #if targetEnvironment(simulator)
            let identifier = info.environment["SIMULATOR_MODEL_IDENTIFIER"] ?? Self.sysctlString("hw.machine")
            let isSimulator = true
        #else
            let identifier = Self.sysctlString("hw.machine")
            let isSimulator = false
        #endif
        return DeviceInfo(
            name: UIDevice.current.name,
            modelIdentifier: identifier,
            isSimulator: isSimulator,
            systemName: UIDevice.current.systemName,
            systemVersion: UIDevice.current.systemVersion,
            systemBuild: Self.sysctlString("kern.osversion"),
            kernelVersion: Self.sysctlString("kern.osrelease"),
            processorCount: info.processorCount,
            activeProcessorCount: info.activeProcessorCount,
            physicalMemory: info.physicalMemory,
            appVersion: bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "",
            appBuild: bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "",
            launchDate: launchDate
        )
    }

    @concurrent
    nonisolated func snapshot() async -> SystemSnapshot {
        let host = mach_host_self()
        defer { mach_port_deallocate(mach_task_self_, host) }
        let (counters, interfaces) = Self.network()
        return SystemSnapshot(
            date: .now,
            memory: Self.memory(host: host),
            cores: Self.cores(host: host),
            process: Self.process(),
            counters: counters,
            interfaces: interfaces,
            bootDate: Self.bootDate(),
            thermalState: ThermalState(ProcessInfo.processInfo.thermalState)
        )
    }

    @concurrent
    nonisolated func storage() async -> StorageStats? {
        let files = FileManager.default
        let home = URL.homeDirectory
        do {
            let values = try home.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityKey])
            guard let total = values.volumeTotalCapacity, let available = values.volumeAvailableCapacity else {
                return nil
            }
            return StorageStats(
                volumeTotal: UInt64(max(0, total)),
                volumeAvailable: UInt64(max(0, available)),
                appBundle: Self.size(of: Bundle.main.bundleURL, files),
                documents: Self.size(of: .documentsDirectory, files),
                applicationSupport: Self.size(of: .applicationSupportDirectory, files),
                caches: Self.size(of: .cachesDirectory, files),
                temporary: Self.size(of: files.temporaryDirectory, files)
            )
        } catch {
            logger.error("Couldn't read volume capacity: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    // MARK: - Memory

    private nonisolated static func memory(host: mach_port_t) -> MemoryStats? {
        var stats = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size
        )
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(host, HOST_VM_INFO64, $0, &count)
            }
        }
        var pageSize: vm_size_t = 0
        guard result == KERN_SUCCESS, host_page_size(host, &pageSize) == KERN_SUCCESS else {
            logger.error("host_statistics64 failed: \(result)")
            return nil
        }
        let page = UInt64(pageSize)
        return MemoryStats(
            total: ProcessInfo.processInfo.physicalMemory,
            free: UInt64(stats.free_count + stats.speculative_count) * page,
            active: UInt64(stats.active_count) * page,
            inactive: UInt64(stats.inactive_count) * page,
            wired: UInt64(stats.wire_count) * page,
            compressed: UInt64(stats.compressor_page_count) * page
        )
    }

    // MARK: - CPU

    private nonisolated static func cores(host: mach_port_t) -> [CoreTicks] {
        var cpuCount: natural_t = 0
        var info: processor_info_array_t?
        var infoCount: mach_msg_type_number_t = 0
        let result = host_processor_info(host, PROCESSOR_CPU_LOAD_INFO, &cpuCount, &info, &infoCount)
        guard result == KERN_SUCCESS, let info else {
            logger.error("host_processor_info failed: \(result)")
            return []
        }
        defer {
            vm_deallocate(
                mach_task_self_, vm_address_t(bitPattern: info),
                vm_size_t(Int(infoCount) * MemoryLayout<integer_t>.stride)
            )
        }
        func ticks(_ index: Int, _ state: Int32) -> UInt32 {
            UInt32(bitPattern: info[index * Int(CPU_STATE_MAX) + Int(state)])
        }
        return (0..<Int(cpuCount)).map { core in
            CoreTicks(
                user: ticks(core, CPU_STATE_USER),
                system: ticks(core, CPU_STATE_SYSTEM),
                idle: ticks(core, CPU_STATE_IDLE),
                nice: ticks(core, CPU_STATE_NICE)
            )
        }
    }

    // MARK: - This process

    private nonisolated static func process() -> AppProcessStats? {
        let task = mach_task_self_

        var vmInfo = task_vm_info_data_t()
        var vmCount = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size)
        let vmResult = withUnsafeMutablePointer(to: &vmInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(vmCount)) {
                task_info(task, task_flavor_t(TASK_VM_INFO), $0, &vmCount)
            }
        }
        guard vmResult == KERN_SUCCESS else { return nil }

        var threads: thread_act_array_t?
        var threadCount: mach_msg_type_number_t = 0
        guard task_threads(task, &threads, &threadCount) == KERN_SUCCESS, let threads else { return nil }
        defer {
            vm_deallocate(
                task, vm_address_t(bitPattern: threads), vm_size_t(Int(threadCount) * MemoryLayout<thread_t>.stride)
            )
        }

        var cpu = 0.0
        for index in 0..<Int(threadCount) {
            var basic = thread_basic_info_data_t()
            var count = mach_msg_type_number_t(
                MemoryLayout<thread_basic_info_data_t>.size / MemoryLayout<integer_t>.size
            )
            let result = withUnsafeMutablePointer(to: &basic) {
                $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                    thread_info(threads[index], thread_flavor_t(THREAD_BASIC_INFO), $0, &count)
                }
            }
            if result == KERN_SUCCESS, basic.flags & TH_FLAGS_IDLE == 0 {
                cpu += Double(basic.cpu_usage) / Double(TH_USAGE_SCALE)
            }
            mach_port_deallocate(task, threads[index])
        }

        return AppProcessStats(
            processID: getpid(),
            threadCount: Int(threadCount),
            cpuUsage: cpu,
            memoryFootprint: vmInfo.phys_footprint,
            memoryAvailable: UInt64(os_proc_available_memory())
        )
    }

    // MARK: - Network

    /// Byte counters for physical interfaces, and the addresses of every interface that is up.
    private nonisolated static func network() -> ([String: InterfaceCounters], [NetworkInterface]) {
        var list: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&list) == 0, let first = list else { return ([:], []) }
        defer { freeifaddrs(list) }

        var counters: [String: InterfaceCounters] = [:]
        var addresses: [String: (ipv4: [String], ipv6: [String])] = [:]

        for pointer in sequence(first: first, next: { $0.pointee.ifa_next }) {
            let entry = pointer.pointee
            let name = String(cString: entry.ifa_name)
            let flags = Int32(entry.ifa_flags)
            guard let address = entry.ifa_addr, flags & IFF_UP != 0, flags & IFF_LOOPBACK == 0,
                isPhysical(name)
            else { continue }

            switch Int32(address.pointee.sa_family) {
            case AF_LINK:
                if let data = entry.ifa_data?.assumingMemoryBound(to: if_data.self).pointee {
                    counters[name] = InterfaceCounters(bytesIn: data.ifi_ibytes, bytesOut: data.ifi_obytes)
                }
            case AF_INET:
                if let host = numericHost(address) { addresses[name, default: ([], [])].ipv4.append(host) }
            case AF_INET6:
                if let host = numericHost(address), !host.hasPrefix("fe80") {
                    addresses[name, default: ([], [])].ipv6.append(host)
                }
            default:
                break
            }
        }

        let interfaces = addresses.keys.sorted().compactMap { name -> NetworkInterface? in
            guard let entry = addresses[name] else { return nil }
            return NetworkInterface(name: name, ipv4: entry.ipv4, ipv6: entry.ipv6)
        }
        return (counters, interfaces)
    }

    /// Ethernet and Wi-Fi are `en*`; tunnels, AirDrop and similar virtual interfaces are left out.
    private nonisolated static func isPhysical(_ name: String) -> Bool {
        name.hasPrefix("en")
    }

    private nonisolated static func numericHost(_ address: UnsafeMutablePointer<sockaddr>) -> String? {
        var buffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        let result = getnameinfo(
            address, socklen_t(address.pointee.sa_len), &buffer, socklen_t(buffer.count), nil, 0, NI_NUMERICHOST
        )
        guard result == 0 else { return nil }
        let host = String(decoding: buffer.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }, as: UTF8.self)
        // Drop the scope suffix of IPv6 addresses (`…%en0`).
        return host.split(separator: "%").first.map(String.init)
    }

    // MARK: - sysctl

    private nonisolated static func bootDate() -> Date? {
        var mib: [Int32] = [CTL_KERN, KERN_BOOTTIME]
        var time = timeval()
        var size = MemoryLayout<timeval>.size
        guard sysctl(&mib, u_int(mib.count), &time, &size, nil, 0) == 0, time.tv_sec > 0 else { return nil }
        return Date(timeIntervalSince1970: Double(time.tv_sec) + Double(time.tv_usec) / 1e6)
    }

    private nonisolated static func sysctlString(_ name: String) -> String {
        var size = 0
        guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 0 else { return "" }
        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname(name, &buffer, &size, nil, 0) == 0 else { return "" }
        return String(decoding: buffer.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }, as: UTF8.self)
    }

    // MARK: - Files

    /// Allocated size of everything below `url`. Missing directories count as empty.
    private nonisolated static func size(of url: URL, _ files: FileManager) -> UInt64 {
        let keys: Set<URLResourceKey> = [.isRegularFileKey, .totalFileAllocatedSizeKey, .fileAllocatedSizeKey]
        guard let enumerator = files.enumerator(at: url, includingPropertiesForKeys: Array(keys)) else { return 0 }
        var total: UInt64 = 0
        for case let file as URL in enumerator {
            guard let values = try? file.resourceValues(forKeys: keys), values.isRegularFile == true else { continue }
            total += UInt64(values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? 0)
        }
        return total
    }
}
