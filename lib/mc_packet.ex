defmodule Minecraft.Packet do
  @moduledoc false
  use Bitwise

  defp unsigned_as_signed(x, bits) do
    # e.g. n >= 2^31. ((2^31)-1 being the largest signed value for 32 bits)
    if x < 1 <<< (bits - 1) do
      x - (1 <<< bits)
    else
      x
    end
  end

  defp signed_as_unsigned(x, bits) do
    if x < 0 do
      x + (1 <<< bits)
    else
      x
    end
  end

  # defp varint(binary) do
  #   varint(binary, [])
  # end

  # defp varint(<<1::1, partial_int::7, rest::binary>>, segment_list) do
  #   varint(rest, [partial_int | segment_list])
  # end

  # defp varint(<<0::1, partial_int::7, rest::binary>>, segment_list) do
  #   int =
  #     [partial_int | segment_list]
  #     |> Enum.map(fn x -> :binary.decode_unsigned(<<0::1>> <> x) end)
  #     |> Enum.reduce(fn x, acc -> (acc <<< 7) + x end)

  #   {int, rest}
  # end

  # defp varint_binary_segment_as_int(x) do
  #   :binary.decode_unsigned(<<0::1>> <> x)
  # end

  # @int_magnitude 1 <<< 32
  # @int_signed_max (1 <<< 31) - 1
  # def varint(x) do
  #   {int, rest} = do_varint(x)

  #   cond do
  #     int >= 1 <<< 32 ->
  #       {:error, " too big"}

  #     # convert to signed
  #     int >= 1 <<< 31 ->
  #       {:ok, int - (1 <<< 32), rest}

  #     true ->
  #       {:ok, int, rest}
  #   end
  # end

  # defp do_varint(<<1::1, low_partial_int::7, rest::binary>>) do
  #   low_partial_int = :binary.decode_unsigned(<<0::1>> <> low_partial_int)
  #   {high_partial_int, rest} = varint(rest)

  #   {(high_partial_int <<< 7) + low_partial_int, rest}
  # end

  # defp do_varint(<<0::1, partial_int::7, rest::binary>>) do
  #   partial_int = :binary.decode_unsigned(<<0::1>> <> partial_int)
  #   {partial_int, rest}
  # end

  def varint(binary) do
    varint(binary, 1, 0)
  end

  defp varint(_, position, _) when position > 5 do
    {:error, "varint too big"}
  end

  # encoding is little endian-ish
  # <<continue::1, int_fragment::7 | <<sign::1, int_fragment_ending::6>>, rest::binary>>
  defp varint(<<1::1, higher::7, rest::binary>>, position, lower) do
    acc = lower + ((higher * 1) <<< (7 * position))
    varint(rest, position + 1, acc)
  end

  defp varint(<<0::1, 0::1, high::6, rest::binary>>, position, low) do
    int = low + ((high * 1) <<< (7 * position))
    {int, rest}
  end

  defp varint(<<0::1, 1::1, high::6, rest::binary>>, position, low) do
    int = low + ((high * 1) <<< (7 * position)) - 2 ** 31
    {int, rest}
  end

  # encoding is little endian-ish
  # <<continue::1, fragment::7 | <<sign::1, end_fragment::6>>, rest::binary>>
  defp varint(<<1::1, fragment::7, rest::binary>>, acc, position) do
    acc = acc + ((fragment * 1) <<< (7 * position))
    varint(rest, acc, position + 1)
  end

  defp varint(<<0::1, sign::1, end_fragment::6, rest::binary>>, acc, position) do
    # `sign` acts as a bool here
    int = acc + ((end_fragment * 1) <<< (7 * position)) - 2 ** 31 * sign
    {int, rest}
  end

  def varint(binary) do
    varint(binary, 1, 0)
  end

  defp varint(_, position, _) when position > 5 do
    {:error, "varint too big"}
  end

  # encoding is little endian-ish
  # <<continue::1, fragment::7 | <<sign::1, end_fragment::6>>, rest::binary>>
  defp varint(<<1::1, fragment::7, rest::binary>>, acc, position) do
    acc = acc + (fragment <<< (7 * position))
    varint(rest, acc, position + 1)
  end

  defp varint(<<0::1, end_fragment::7, rest::binary>>, acc, position) do
    uint = acc + (end_fragment <<< (7 * position))
    {unsigned_as_signed(uint), rest}
  end


end

#    partial_int = :binary.decode_unsigned(partial_int)
