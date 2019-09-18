# credits Ludovic Rousseau, https://ludovicrousseau.blogspot.com/2010/06/pcsc-sample-in-ruby.html

require 'smartcard'

EF_ID_CARTA = "10001003"
EF_DATI_PERSONALI_LENGTH = 6

SELECT_APDU = %w{00 A4 08 00}
READ_BINARY_APDU = %w{00 B0 00 00} # when offset is 0

EF_DATI_PERSONALI = %w{11 00 11 02} # array of string; strings should be read as hex
CARD_ID_HEADER = "8038000"

TIMEOUT = 0.5

def pack_apdu(apdu)
  apdu.pack('H2'*apdu.size)
end

# to compose the full apdu you need:
# * select apdu
# * length of the next token (directory path) in hex
# * directory to move in; can be nested (DF0\EF_ID_CARTA = 10 00\10 03)
def compose_select_apdu(directory)
  size = directory.size
  pack_apdu(SELECT_APDU + [ sprintf("%02x", size) ] + directory)
end

def compose_read_apdu(length)
  pack_apdu(READ_BINARY_APDU + [ sprintf("%02x", length) ])
end


context = Smartcard::PCSC::Context.new(:system)
readers = context.readers

reader = readers.first

# Connect to the card
card = Smartcard::PCSC::Card.new(context, reader)

puts card_status = card.info

while ( res = ( card.transmit(compose_select_apdu(EF_DATI_PERSONALI))).unpack('H*') ) != ["9000"]
  puts "change dir res: #{res}" if $DEBUG
  sleep TIMEOUT
end
while ( raw_length = card.transmit(compose_read_apdu(EF_DATI_PERSONALI_LENGTH)).unpack('H*').first ) !~ /9000$/
  puts "ask for raw_length res: #{raw_length}" if $DEBUG
  sleep TIMEOUT
end

puts "raw_length: #{raw_length}"
puts (raw_length[0..(EF_DATI_PERSONALI_LENGTH * 2)].scan /../).map {|c| c.to_i(16).chr}.join




# Disconnect
card.disconnect
context.release



