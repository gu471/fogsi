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
