#FOGSI - FOG- & OPSI-Server

## Voraussetzungen

Mögliche Testumgebung: [Oracle VirtualBox](https://www.virtualbox.org/wiki/Downloads)

Betriebssystem: [Debian Wheezy] (https://www.debian.org/distrib/) (Net-Install)

Sollte der PC in einer VM laufen, dann sollte das Netzwerk über eine Netzwerkbrücke angebunden werden.
Die Festplattengröße sollte großzügig ausfallen, da die Images unter `/images` auf dem System abgelegt werden. Andernfalls sollten externe Speicher eingebunden werden.

Bei der Betriebssysteminstallation sollten "nichtfreie" Pakte mit in die aptitude-Links aufgenommen werden. 

Der Netzwerkname sollte sinnvoll geändert werden, um den PC über die Browser auch ohne IP einfach erreichen zu können. Zudem sollte die Domäne angegeben werden, damit der PC über den FQDN ordentlich angesprochen und das Netzwerk auch entsprechend von Server erreicht werden kann.

Als Packete sind lediglich die Standard-Tools und der SSH-Server nötig.

## Server-Installation

vor dem Start der Installation:

```bash
apt-get update
apt-get dist-upgrade
```

### OPSI
Voraussetzungen für OPSI:
```bash
aptitude install wget lsof host python-mechanize p7zip-full cabextract openbsd-inetd pigz samba samba-common smbclient cifs-utils samba-doc mysql-server
```

Bei der Installation wird nach einem Passwort für die MySQL-Datenbank gefragt. Das Passwort kann leer gelassen werden, da standardmäßig auf die Datenbank nur mit einem lokalen Account zugegriffen werden kann.

Nun wollen wir OPSI installieren, dazu müssen die nötigen Ressourcen aptitude bekanntgegeben werden:
```
nano /etc/apt/sources.list
```

Am Ende der Datei muss man folgende Quelle hinzufügen:

> __deb http://download.opensuse.org/repositories/home:/uibmz:/opsi:/opsi40/Debian_7.0 ./__

Damit aptitude beim Aktualisieren und Herunterlanden nicht meckert, müssen wir noch den Schlüssel für die Quelle herunderladen und apt mitteilen:

```
wget -O - http://download.opensuse.org/repositories/home:/uibmz:/opsi:/opsi40/Debian_7.0/Release.key | apt-key add -
```

Nun aktualisieren wir den Packet-Manager und deinstallieren tftpd, da OPSI einen eigenen TFTP-Server mitbringt.

```
aptitude update
aptitude safe-upgrade
aptitude remove tftpd
update-inetd --remove tftpd
```

Jetzt kann OPSI installiert werden, dazu gehört auch JAVA, da OPSI zur Verwaltung ein Java-Interface nutzt.

```
aptitude install opsi-atftpd
aptitude install opsi-depotserver
aptitude install opsi-configed
aptitude install openjdk-7-jre icedtea-7-plugin
```

OPSI ist nun unter `https://<serverip|servername>:4447/configed/` erreichbar. Als Nutzer wird der während der Installation eingerichtete verwendet.

### FOG

Da das Imaging der PCs über FOG laufen soll, müssen wir zuerst die OPSI-Pakete bei einem zukünftigen apt-get upgrade ignorieren lassen, um sicher zu gehen, dass OPSI die FOG-Installation nicht zerschießt:

```
aptitude hold opsi-atftpd opsi-depotserver opsi-configed
```

Jetzt können wir FOG installieren: 

```
cd /opt/
http://downloads.sourceforge.net/project/freeghost/FOG/fog_1.2.0/fog_1.2.0.tar.gz
tar -xvzf fog_1.2.0.tar.gz
cd fog_1.2.0/bin/
./installfog.sh 
```

Die Eingaben handelt man wie folgt ab:

> Enter
>
> Enter
>
> Enter (IP überprüfen)
>
> N (router)
>
> N (DHCP)
>
> Enter
>
> N (DHCP-serv)
>
> Enter
>
> Enter
>
> Enter (Press enter to acknowledge this message.)
>
> Enter (Wenn mysql passwort leer)
>
> (STOP)	"Press [Enter] key when database is updated/installed."

Hier öffnet man das zukünftige Verwaltungsinterface über: `http://<serverip>/fog` und initialisiert die Datenbank. Danach fährt man mit der Installation mit der Eingabetaste fort.

Der erste Login nach der Installation erfolgt über:

> user: fog
>
> pass: password

Jetzt sollte man den DHCP im Netzwerk so einrichten, dass er folgende Daten weitergibt:

> nextserver:	(server IP)
>
> pxe-image:	undionly.kpxe

Nun muss lediglich noch ein Link gesetzt werden:

```
cd /tftpboot
ln -s undionly.kpxe undionly.0
```

Eine Beispielkonfiguration eines DHCP-Server im Netzwerk einer Fritzbox findet man unter:
https://github.com/gu471/fogsi/tree/master/dhcp/etc

Bei der Nutzung von FOG als [DHCP-Proxy](http://fogproject.org/wiki/index.php/Setting_up_ProxyDHCP) gibt es nach dem Neustart der Virtuellen Maschine Probleme beim Herunterladen der `/tftpboot/default.ipxe`

Komprimierung beim Image erstellen verringern (schneller, größere Images)

```
mysql -uroot
use fog;
UPDATE globalSettings SET settingValue = '5' WHERE settingKey = 'FOG_PIGZ_COMP';
exit
```

Vor der Aufnahme eines PCs sollte unter `Image Management->Create Image` im FOG ein Image erstellt werden. Als Image-Typ sollte `Multipartition, Singledisk` ausgewählt werden.

## Hardware-Voraussetzungen der Client-PCs

BIOS:
```
BOOT:
  Secureboot: aus
	boot order:	*, Network, HDD, *
UEFI: legacy
PXE: an, IPv4 an, IPv6 aus
```

## Nutzung der Clients (erste Tests):

### FOG:

Bei dem ersten Start eines PCs wird das FOG-Image geladen und man kann jetzt den PC in das FOG-Verzeichnis aufnehmen.
Die dort getätigten Angaben kann man im Web-FrontEnd wieder ändern.

Damit der FOG-Service vollumfänglich genutzt werden kann, muss noch der FOG-Service installiert werden.
Diesen findet man unter `http://<serverip|servername>/fog/client`. Man sollte alle Teilservices installieren, die Konfiguation erfolgt über das Web-FrontEnd.

### OPSI:

Damit der Client mit OPSI kommunizieren kann, muss man ihn in der Regel manuell einbinden, nachdem man den Client-Service eingebunden hat. Das muss prinzipiell auch manuell für jeden Client nach dem Aufspielen eines Images durchgeführt werden (dazu später mehr).

Den Client findet man unter `\\<serverip|servername>\opsi_depot\opsi-client-agent`. Zum Installieren führt man die silent_setup.cmd aus, nachdem man im Unterordner `\files\opsi\cfg` den Benutzernamen und das Passwort eingetragen hat.
Das Passwort sollte unter keinen Umständen auf dem Server hinterlegt werden.

## Workarounds und Client-Konfigurationen:

### Windows installieren

Auf der Hardware sollte Windows im audit-Modus installiert werden. 

Dazu startet man die Installation. Sobald der Dialog erscheint, in dem man Benutzername und Computername eingeben sollt, drückt man `Strg+Shift+F3`. Der PC startet nun standardmäßig bis zum Deploy als Administrator im audit-Modus.

Zuerst sollte man alle Windows-Updates installieren (dauert bekanntlich länger ;))

Danach sollte man den PC in `*FogImage*` umbenennen, dazu später mehr.

### FOG-Client installieren

Unter `http://<serverip|servername>/fog/client`lädt man den Client herunter und installiert ihn.
Wichtig ist die korrekte IPfür den FOG-Server anzugeben. Es können alle PlugIns installiert werden, die Konfiguration erfolgt über das Interface.

### OPSI-Installation vorbereiten

Man lädt den Ordner `\\<serverip|servername>\opsi_depot\opsi-client-agent` nach `C:\opsi-client-agent` herunter. Und richtet dort im Unterordner `\files\opsi\cfg` Benutzername und Passwort ein. Damit die Dateien nach einem Deploy des Images nicht mehr auf dem PC vorhanden sind, geht man wie folgt vor:

- [x] Anlegen des Ordners `C:\cmds\`
- [x] Kopieren der Datei [installopsi.cmd](https://github.com/gu471/fogsi/tree/master/client/C/cmds) in eben diesen Ordner
- [x] Öffnen der mmc->Datei->SnapIn hinzufügen->Aufgabenplanung

Hier erstellt man eine Aufgabe:

> Beim Computerstart ausführen
>
> die Datei `C:\cmds\installopsi.cmd` ausführen
>
> Nach dem Fertigstellen Eigenschaften öffnen
>
> Beim Ausführen der Aufgabe folgendes Benutzerkonto verwenden: SYSTEM

Hintergrund des Skripts:
Nach dem Deployment ändert FOG automatisch den PC-Namen in den im Interface eingestellten und startet automatisch neu. Aus diesem Grund darf OPSI nicht beim ersten Start installiert werden. Sobald der PC nicht mehr das Format `*FogImage*` erfüllt, startet das Skript die Installation von OPSI, dadurch wird der PC auch mit dem korrekten PC-Namen im OPSI registriert.
Das Anlegen des Ordners `C:\cmds\opsiinstalled` ist nötig, da nach der Installation der Neustart so schnell durchgeführt wird, dass der Ordner des OPSI-Clients mit den Anmeldeinformationen nicht gelöscht werden kann. Das wird dann beim nächsten Neustart nachgeholt.

OPSI ist jetzt installiert und es kann weitere Software nachinstalliert werden. Die Installation dieser Software erfolgt automatisch beim Start des PCs vor dem Einloggen eines Nutzers. Kann aber über "on-demand" im OPSI-Interface erzwungen werden.

### Deployment - WindowsImage

Um ein Image deployen zu können, muss es sich vorher im Audit-Modus befinden (s.o.).

In der Regel kann man auch das Skript unter https://github.com/gu471/fogsi/tree/master/client/C/cmds/sysprep nutzen, um einen PC in den Autid-Modus zu versetzen. Das funktioniert aber nicht immer. (Vorkonfiguration durch Zulieferer?)

Mit eben diesem Skript, kann man auch den PC in den OOBE (Out Of the Box Experience)-Modus versetzen. Option 1 bzw. 2.

Dadurch führt der PC eine Schnellinstallation durch, bei der unter anderen SIDs neu gesetzt werden. Das ist wichtig, damit es in der Domäne nicht zu Irritationen kommt. Insbesondere ist das für die zukünfitgen Windows-Updates wichtig, da der WSUS-Server anscheinend eine Datenbank mit Clientkonfigurationen besitzt.

Unter `C:\cmds\sysprep\` befinden sich zwei Skripte. Beide geben der Schnellinstallation Antworten vor. Option 1 setzt die Windowsaktivierung zurück, wodurch sich Windows automatisch beim Neustart aktiviert (max. 3 Mal möglich bei MAK-Lizenzen). Bei Option 2 wird dieses Zurücksetzen umgangen. Der Rest der beiden Sktipte ist identisch und sollte vor einem Deploy nochmal überprüft werden, um es den Gegebenheiten anzupassen. (Windows System Image Manager aus dem WAIK)

Soll das Image in den Deploy-Modus gesetzt werden (Option 1 + 2), ist es wichtig, dass bei Start danach sofort das Image erzeugt wird!

### Deployment - Software

Unter `\\<serverip|servername>\opsi_depot\opsi-setup-detector` findet man ein Programm, mit dem man Installationen für das Deployment via OPSI vorbereiten kann.

Sollten Installationsdateien nicht erkannt werde, sollte man schauen, ob es für das Programm eine .msi gibt.
Getestet wurde es erfolgreich mit OpenOffice und Mozilla. Ebenso mit IrfanView, für das man im Netz eine Anleitung findet.
Generell ist jede zu installierende Software ein Problem für sich. Für oft genutzte Software findet man aber in der Regel im Netz Walkthrougs.

Der vom detector erzeugte Ordner ist nach `\\opsi\opsi_workbench` zu kopieren.

Auf dem Server sind nun folgende Befehle auszuführen:

```
cd /home/opsiproducts/<software>
opsi-makeproductfile
opsi-package-manager -i <software>.opsi
```

Nun kann die Software über das Interface an die Clients verteilt werden.

#### Anpassung der Starthomepage von Firefox (google.de als Start)

- [x] msi mit setupdetector öffnen und speichern
- [x] mozilla.cfg aus der msi extrahieren (7zip)
- [x] mozilla.cfg erweitern um:

> lockPref("browser.startup.homepage", "http://www.google.de");


- [x] mozilla.cfg in `/home/opsiproducts/<firefox>/CLIENT_DATA/` kopieren (bzw. `\\<serverip|servername\opsi-workbench\<firefox>\CLIENT_DATA\`
- [x] Setupskript erweitern:

nach:	`Winbatch_install_msi`

hinzufügen: `Files_StartPage`

nach dem darauf folgenden `endif`
hinzufügen:
```
[Files_StartPage]
copy "%SCRIPTPATH%\mozilla.cfg" "C:\Program Files (x86)\Mozilla Firefox\"
```

Paket wie oben beschrieben bereitstellen (auf der Serverkonsole):

```
cd /home/opsiproducts/<firefox>
opsi-makeproductfile
opsi-package-manager -i <firefox>.opsi
```

`%SCRIPTPATH%` verweist dabei auf den mit `opsi-package-manager -i <firefox>.opsi` automatisch angelegten Ordner `\\<serverip|servername\opsi-depot\<firefox>\CLIENT_DATA\`.
