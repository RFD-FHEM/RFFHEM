# Ausführen von Unit-Tests

## Standard FHEM Module (Verzeichnis `FHEM/`)

Unit-Tests für Standard FHEM-Module, die im Verzeichnis `FHEM/` liegen (z.B. `FHEM/00_SIGNALduino.pm`), sollten nach folgendem Schema ausgeführt werden:

```bash
prove -v -I FHEM -r --exec 'perl fhem.pl -t' <Pfad_zur_Testdatei>
```

Beispiel:
```bash
prove -v -I FHEM -r --exec 'perl fhem.pl -t' t/FHEM/00_SIGNALduino/08_DeviceData_rmsg.t
```

## Perl Library Module (Verzeichnis `lib/`)

Unit-Tests für Perl-Module im Verzeichnis `lib/` (z.B. `lib/FHEM/Devices/SD/Logger.pm`) werden wie folgt ausgeführt:

```bash
prove -v --exec 'perl -I lib -I FHEM' -r <Pfad_zur_Testdatei>
```

Beispiel:
```bash
prove -v --exec 'perl -I lib -I FHEM' -r t/FHEM/Devices/SD/Matchlist.t
```
