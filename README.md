# Tessera sanitaria

The Italian health insurance card (tessera sanitaria) [1] since some time sports a RFID/Calypso-like interface to access cardholder's data.

I tried ACR122U NFC reader with CCID [2] library on Debian GNU/Linux. 

To make sense of the content, you need the filesystem specs from agid [3].

## DF1/EF_Dati_Personali

Holds name, surname, cardholder's taxpayer number, card's expiration and more.

The first 6 bytes are the field's length as hex number ASCII encoded: an 
example response of `3030303036389000` means: strip the last four bytes 
(it's the response code 90 00 that is ok). 0x30 is ASCII 0, 
0x36 is 6, 0x38 is 8. So field's payload's length is 0x68 bytes. 

The payload is divided into fields. Before each field there are two bytes
 for the field's length. Again as hex ASCII encoded (a `3130` means 0x10 or
  16). When a field has length 0, just skip to the next field.
  
The first fields are: 
- issuer 
- date of issue  as DDMMYYYY
- expiration's date  as DDMMYYYY
- surname
- name
- date of birth as DDMMYYYY
- sex (F or M)
- heigth (should be empty) 
- Italian taxpayer number (codice fiscale)
- city of issue
- city of residence as ISTAT code;
- street of residence;

## DF0/EF_ID_Carta
 
Card number as hex ASCII encoded. 

To obtain full 20 digit card number as 
printed on the back side:
* read 13 char and discard the first;
* add fixed prefix (`8038000`) in front of 
what you read;
* calculate luhn checksum of 
all the previous (prefix + number read);
* add checksum as last char. [1]
  
## Try it with ruby

    bundle install
    # -d is just for debug
    bundle exec ruby -d tessera_sanitaria.rb  
    
    
Many thanks Giuseppe Tondi.    
  
[1] https://sistemats1.sanita.finanze.it/portale/documents/20182/34254/allegato%2Btecnico%2BTS-CNS%2Bex%2BDL%2B78-2010_v22-06-12.pdf/2ef2b969-879c-64f5-2b0a-8bce9877c08f

[2] https://ccid.apdu.fr/

[3] https://www.agid.gov.it/sites/default/files/repository_files/documentazione_trasparenza/filesystemcns_20131216.pdf