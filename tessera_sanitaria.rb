# credits Ludovic Rousseau, https://ludovicrousseau.blogspot.com/2010/06/pcsc-sample-in-ruby.html

require 'smartcard'
require 'luhn'

FIELDS = %w{issuer issue_data expiration_date surname given_name date_of_birth sex heigth tax_payer_number
city_of_issue city_of_residence street}

EF_DATI_PERSONALI_LENGTH = 12 # 12 bytes: 6 chars after decoding

SELECT_APDU       = %w{00 A4 08 00}
READ_BINARY_APDU  = %w{00 B0 00 00} # when offset is 0

EF_DATI_PERSONALI = %w{11 00 11 02} # array of string; strings should be read as hex
EF_ID_CARTA       = %w{10 00 10 03}
CARD_ID_LENGTH = 13
CARD_ID_HEADER = "8038000"

TIMEOUT = 0.5
OK_RESPONSE_CODE = "9000"

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

# length is a base 10 number
def compose_read_apdu(length)
  pack_apdu(READ_BINARY_APDU + [ sprintf("%02x", length) ])
end

def ascii_convert(data)
  (data.scan(/../)).map {|c| c.to_i(16).chr}.join
end

# skip PAYLOAD_LENGTH_FIELD_SIZE bytes because it's no actual payload
def parse(data)
  do_parse( ascii_convert(data[EF_DATI_PERSONALI_LENGTH..-1]), {}, 0)
end

# data -> data yet to process; result -> result already calculated as a hash; index -> current index of FIELDS
def do_parse(data, result, index)
  return result if ( data.empty? or index >= FIELDS.size )
  length = data[0...2].to_i(16) # length is two bytes as hex
  payload = data[2...(length + 2)]
  tail = data[(length + 2)..-1]
  result[FIELDS[index]] = payload
  do_parse(tail, result, index + 1)
end

def card_id(raw_data)
  card_stem = "#{CARD_ID_HEADER}#{ascii_convert(raw_data[2...-4])}" # trim last four bytes because it's reponse code
  control_digit = Luhn.control_digit(card_stem)
  "#{card_stem}#{control_digit}"
end

context = Smartcard::PCSC::Context.new(:system)
readers = context.readers

reader = readers.first

# Connect to the card
card = Smartcard::PCSC::Card.new(context, reader)

puts card_status = card.info if $DEBUG

while ( res = ( card.transmit(compose_select_apdu(EF_DATI_PERSONALI))).unpack('H*') ) != [ OK_RESPONSE_CODE ]
  puts "change dir res: #{res}" if $DEBUG
  sleep TIMEOUT
end
while ( raw_length = card.transmit(compose_read_apdu(EF_DATI_PERSONALI_LENGTH)).unpack('H*').first ) !~ /#{OK_RESPONSE_CODE}$/
  puts "raw_length ef_dati_personali response: #{raw_length}" if $DEBUG
  sleep TIMEOUT
end

puts "EF_Dati_Personali raw_length: #{raw_length}" if $DEBUG
ef_dati_personali_payload_length = ascii_convert(raw_length[0..EF_DATI_PERSONALI_LENGTH]).to_i(16)

while ( raw_payload = card.transmit(compose_read_apdu(ef_dati_personali_payload_length)).unpack('H*').first ) !~ /#{OK_RESPONSE_CODE}$/
  puts "raw_payload ef_dati_personali response: #{raw_payload}" if $DEBUG
  sleep TIMEOUT
end
puts raw_payload if $DEBUG
puts parse(raw_payload)

while ( res = ( card.transmit(compose_select_apdu(EF_ID_CARTA))).unpack('H*') ) != [ OK_RESPONSE_CODE ]
  puts "change dir res: #{res}" if $DEBUG
  sleep TIMEOUT
end
while ( raw_card_id = card.transmit(compose_read_apdu(CARD_ID_LENGTH)).unpack('H*').first ) !~ /#{OK_RESPONSE_CODE}$/
  puts "raw_card_id response: #{raw_card_id}" if $DEBUG
  sleep TIMEOUT
end
puts raw_card_id if $DEBUG
puts "card_id: #{card_id(raw_card_id)}"


# Disconnect
card.disconnect
context.release



