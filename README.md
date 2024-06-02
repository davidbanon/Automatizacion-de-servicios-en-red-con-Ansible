Este proyecto tiene como finalidad automatizar un servidor DNS y DHCP con ayuda de Ansible y Nmap.

En la guía se puede ver la realización paso a paso del proyecto.

Estructura: 3 nodos interconectados por SSH con dos interfaces de red, una interna y otra con salida a internet. El proyecto trabaja sobre la interfaz interna, desplegando sobre esta los servicios DNS y DHCP mediante Ansible, Nmap y un conjunto de scripts que permiten la detección de usuarios en la red y la reserva de IP y nombre para cada usuario.
