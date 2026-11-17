# 0004. Systemdata på tvOS

- **Status:** Accepterad
- **Datum:** 2026-11-18

## Sammanhang

Appen görs om från en indexdashboard till en dashboard över Apple TV:ns egna systemdata: minne, lagring,
processor, processer, appar, drifttid, tvOS-version och nätverk. tvOS-sandlådan begränsar vad en app får läsa,
och appen ska kunna gå igenom App Store-granskning – alltså inga privata API:er.

## Beslut

Vi läser bara det som publika, dokumenterade API:er ger inne i sandlådan:

| Data | Källa |
|---|---|
| RAM (fritt, aktivt, inaktivt, låst, komprimerat) | `host_statistics64(HOST_VM_INFO64)` + `ProcessInfo.physicalMemory` |
| CPU-belastning per kärna | `host_processor_info(PROCESSOR_CPU_LOAD_INFO)`, skillnad mellan två mätningar |
| Den egna processen (CPU, trådar, minne, minnesgräns) | `task_threads`/`thread_info`, `task_info(TASK_VM_INFO)`, `os_proc_available_memory()` |
| Lagring | `URLResourceValues.volumeTotalCapacity`/`volumeAvailableCapacity`, storlek på appens egna mappar |
| Drifttid | `sysctl(KERN_BOOTTIME)` – räknar även tid i viloläge, till skillnad från `ProcessInfo.systemUptime` |
| Modell, tvOS-version, build, kärna | `sysctl` (`hw.machine`, `kern.osversion`, `kern.osrelease`), `UIDevice` |
| Nätverkstrafik | `getifaddrs`, byte-räknare (`if_data`) för `en*`-gränssnitt, skillnad mellan två mätningar |
| Anslutning, router, IPv4/IPv6 | `NWPathMonitor` |
| Temperatur | `ProcessInfo.thermalState` |

Systemdata samplas varannan sekund medan appen syns, lagring en gång i minuten (den går igenom filer). Allt
ligger bakom `SystemMetricsProviding` och `NetworkPathMonitoring` så att modellerna kan testas med fejkdata.

## Alternativ som övervägdes

- *Topplista över processer via `sysctl(KERN_PROC_ALL)`:* sedan iOS 9/tvOS 9 returnerar anropet bara den egna
  processen i sandlådan. I simulatorn skulle det lista Macens processer, vilket är missvisande. Vi visar den egna
  processen och förklarar begränsningen i UI:t.
- *Lista installerade appar och deras storlek (`LSApplicationWorkspace` m.fl.):* privata API:er, avvisas i App
  Store och kan sluta fungera när som helst. Vi visar appens eget lagringsutrymme och hänvisar till
  *Inställningar → Allmänt → Hantera lagring*.
- *Wi-Fi-namn (SSID) och signalstyrka:* inte tillgängligt för appar på tvOS.

## Konsekvenser

- Användaren får ärliga siffror, men två av de ursprungliga önskemålen (topp 10-processer, antal appar och
  appstorlekar) går inte att uppfylla på tvOS. UI:t säger det i klartext i stället för att visa tomma listor.
- Byte-räknarna i `if_data` är 32-bitars och slår runt vid 4 GiB. Hastigheter räknas med wrapping-aritmetik;
  totalen "sedan omstart" är modulo 4 GiB per gränssnitt.
- I simulatorn kommer RAM, CPU och lagring från Macen. Appen visar "Simulator" under Enhet.
