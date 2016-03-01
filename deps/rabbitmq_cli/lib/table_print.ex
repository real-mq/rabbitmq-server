## The contents of this file are subject to the Mozilla Public License
## Version 1.1 (the "License"); you may not use this file except in
## compliance with the License. You may obtain a copy of the License
## at http://www.mozilla.org/MPL/
##
## Software distributed under the License is distributed on an "AS IS"
## basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
## the License for the specific language governing rights and
## limitations under the License.
##
## The Original Code is RabbitMQ.
##
## The Initial Developer of the Original Code is GoPivotal, Inc.
## Copyright (c) 2007-2016 Pivotal Software, Inc.  All rights reserved.


defmodule TablePrint do

  @n_app_divider_space 3

  def print_table(result, _, _) when not is_list(result), do: nil
  def print_table(result, field, table_name) do
    case result[field] do
      nil -> nil
      []  -> IO.puts "#{table_name}: None"
      _   -> tuple_to_table(result[field], table_name)
    end
  end

  def tuple_to_table(nil, _), do: nil
  def tuple_to_table([], _), do: nil
  def tuple_to_table(table, table_name) do
    ncols = table |> List.first |> tuple_size
    widths = column_widths(table, ncols)
    io_format_str = generate_io_format(List.first(table), widths)

    print_table_name(table_name)
    print_dashed_line(widths)

    Enum.map(
      table,
      fn (field_tuple) ->
        :io.format(io_format_str, Tuple.to_list(field_tuple))
      end
    )
  end

  def generate_io_format({}, _), do: ""
  def generate_io_format(_, {}), do: ""
  def generate_io_format(field_tuple, field_widths) do
    io_str = List.zip([field_widths |> Tuple.to_list, field_tuple |> Tuple.to_list])
    |> Enum.map(fn({width, name}) -> "~-#{width}#{io_wildcard(name)}" end)
    |> Enum.join(" | ")

    io_str <> "\n"
  end

  # Calculates the widths needed to print the given columns
  def column_widths(tuple_list, ncols) do
    case tuple_list do
      nil   -> List.duplicate(0, ncols) |> List.to_tuple
      []    -> List.duplicate(0, ncols) |> List.to_tuple
      _ -> tuple_list |> get_field_widths |> max_accumulator(ncols)
    end
  end

  def print_dashed_line(nil), do: nil
  def print_dashed_line({}), do: nil
  def print_dashed_line(field_widths) do
    line_length = dividing_line_length(field_widths)
    IO.puts String.duplicate("-", line_length)
  end

  defp get_field_widths(tuple_list) do
    tuple_list |> Enum.map(
      fn(tup) ->
        tup
        |> Tuple.to_list
        |> Enum.map(&elt_length/1)
      end
    )
  end

  # input:  a list of n-element lists generated by get_field_widths
  #         an integer of value > 0 representing the number of fields
  # output: an n-tuple containing the largest element in each column.
  defp max_accumulator(app_widths_list, ncols) do
    Enum.reduce(
      app_widths_list,
      List.duplicate(0, ncols),
      fn (app_widths, acc) ->
        List.zip([app_widths, acc])
        |> Enum.map(fn({a,b}) -> max(a,b) end)
        |> List.to_tuple
      end
    )
  end

  defp dividing_line_length(field_widths) do
    field_widths
    |> Tuple.to_list
    |> Enum.sum
    |> + (@n_app_divider_space * num_dividers(field_widths))
  end

  defp num_dividers(field_widths) do
    tuple_size(field_widths) - 1
  end

  defp elt_length(target) when is_list(target) do
    target |> length
  end

  defp elt_length(target) when is_atom(target) do
    target |> Atom.to_char_list |> length
  end

  defp elt_length(target) when is_integer(target) do
    target |> Integer.to_char_list |> length
  end

  defp print_table_name(nil), do: nil
  defp print_table_name(""), do: nil
  defp print_table_name(name) when is_binary(name), do: IO.puts "#{name}:"
  defp print_table_name(name) when is_list(name), do: IO.puts "#{name}:"

  defp io_wildcard(field) when is_integer(field), do: "w"
  defp io_wildcard(field) when is_atom(field), do: "w"
  defp io_wildcard(field) when is_float(field), do: "w"
  defp io_wildcard(field) when is_binary(field), do: "s"
  defp io_wildcard(field) when is_list(field), do: "s"
end
