# Tessera sanitaria

The Italian health insurance card (tessera sanitaria) [1] since some time sports a RFID/Calypso-like interface to access cardholder's data.

I tried ACR122U NFC reader with CCID [2] library on Debian GNU/Linux. 

To make sense of the content, you need the filesystem specs from agid [3].

As a starting point, a few informations can be found in: 
* `DF0/EF_ID_Carta`: card number as ASCII code. To obtain full card number as 
printed on the back side, add fixed prefix (`8038000`) and luhn checksum of 
all the previous (prefix + card number) as last char [1];
* `DF1/EF_Dati_Personali`: 

[1] https://sistemats1.sanita.finanze.it/portale/documents/20182/34254/allegato%2Btecnico%2BTS-CNS%2Bex%2BDL%2B78-2010_v22-06-12.pdf/2ef2b969-879c-64f5-2b0a-8bce9877c08f

[2] https://ccid.apdu.fr/

[3] https://www.agid.gov.it/sites/default/files/repository_files/documentazione_trasparenza/filesystemcns_20131216.pdf