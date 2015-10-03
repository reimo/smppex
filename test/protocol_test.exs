defmodule SMPPEX.ProtocolTest do
  use AssertHelpers
  use HexHelpers

  import SMPPEX.Protocol

  test "parse: insuficient data" do
    assert parse(<<1,2,3,4,5,6,7,8,9,0,1,2,3,4,5>>) == {:ok, nil, <<1,2,3,4,5,6,7,8,9,0,1,2,3,4,5>>}
    assert parse(<<1,2,3>>) == {:ok, nil, <<1,2,3>>}
  end

  test "parse: bad command_length" do
    assert {:error, _} = parse(from_hex "00 00 00 0F   00 00 00 00   00 00 00 00   00 00 00 00")
  end

  test "parse: bad command_id" do
    parse_result = parse(from_hex "00 00 00 10   80 00 33 02   00 00 00 00   00 00 00 01   AA BB CC")

    assert {:ok, _, _} = parse_result

    {:ok, pdu, tail} = parse_result

    assert tail == from_hex("AA BB CC")
    assert pdu.command_id == 0x80003302
    assert pdu.command_name == nil
    assert pdu.command_status == 0
    assert pdu.sequence_number == 1
    assert pdu.valid == false
  end

  test "parse: good header" do
    parse_result = parse(from_hex "00 00 00 10   80 00 00 02   00 00 00 00   00 00 00 01   AA BB CC")

    assert {:ok, _, _} = parse_result

    {:ok, pdu, tail} = parse_result

    assert tail == from_hex("AA BB CC")
    assert pdu.command_id == 0x80000002
    assert pdu.command_name == :bind_transmitter_resp
    assert pdu.command_status == 0
    assert pdu.sequence_number == 1
    assert pdu.valid == true
  end

  test "parse: bind_transmitter" do

    data =  """
      00 00 00 30 00 00 00 02 00 00 00 00 00 00 00 01
      74 65 73 74 5f 6d 6f 33 00 59 37 6c 48 7a 76 46
      6a 00 63 6f 6d 6d 00 7b 01 02 72 61 6e 67 65 00
    """

    parse_result = parse(from_hex data)

    assert {:ok, _, _} = parse_result

    {:ok, pdu, _} = parse_result

    assert pdu.command_id == 0x00000002
    assert pdu.command_name == :bind_transmitter
    assert pdu.command_status == 0
    assert pdu.sequence_number == 1
    assert pdu.valid == true

    assert pdu.mandatory[:system_id] == "test_mo3"
    assert pdu.mandatory[:password] == "Y7lHzvFj"
    assert pdu.mandatory[:system_type] == "comm"
    assert pdu.mandatory[:interface_version] == 123
    assert pdu.mandatory[:addr_ton] == 1
    assert pdu.mandatory[:addr_npi] == 2
    assert pdu.mandatory[:address_range] == "range"

  end

end
