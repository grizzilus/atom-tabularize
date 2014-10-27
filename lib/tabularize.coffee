_ = require 'underscore'

module.exports =
  class Tabularize

    @tabularize: (separator, editor) ->
      editor.mutateSelectedText (selection, index) ->
        lines = selection.getText().split("\n")

        lines = _(lines).map (line) ->
          line.split(separator)

        # Strip spaces
        #   - Only from non-delimiters; spaces in delimiters must have been matched
        #     intentionally
        #   - Don't strip leading spaces from the first element; we like indenting.

        num_columns = 0
        stripped_lines = _.map lines, (cells) ->
          num_columns = cells.length if cells.length > num_columns
          cells = _.map cells, (cell, i) ->
            if i == 0
              Tabularize.stripTrailingWhitespace(cell)
            else
              cell.trim()

        padded_columns = (Tabularize.paddingColumn(i, stripped_lines) for i in [0..num_columns-1])

        padded_lines = (Tabularize.paddedLine(i, padded_columns) for i in [0..lines.length-1])

        result = _(padded_lines).map (line) ->
          Tabularize.stripTrailingWhitespace(line.join(" #{separator} "))
        .join("\n")

        selection.insertText(result)

    # Left align 'string' in a field of size 'fieldwidth'
    @leftAlign: (string, fieldWidth) ->
      if string is null
        return null
      spaces = fieldWidth - string.length
      right = spaces
      "#{string}#{Tabularize.repeatPadding(right)}"

    @stripTrailingWhitespace: (text) ->
      text.replace /\s+$/g, ""

    @repeatPadding: (size) ->
      Array(size+1).join ' '

    # Pad cells of the #nth column
    @paddingColumn: (col_index, matrix) ->
      # Extract the #nth column, extract the biggest cell while at it
      cell_size = 0
      column = _(matrix).map (line) ->
        if line.length > col_index
          cell_size = line[col_index].length if cell_size < line[col_index].length
          line[col_index]
        else
          null

      # Pad the cells
      (Tabularize.leftAlign(cell, cell_size) for cell in column)

    # Extract the #nth line
    @paddedLine: (line_index, columns) ->
      # extract #nth line, filter null values and return
      _.chain(columns).map (column) ->
        column[line_index]
      .filter (cell) ->
        !(cell is null)
      .value()
