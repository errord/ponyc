use "buffered"

class FileLines is Iterator[String iso^]
  """
  Iterate over the lines in a file.
  """
  let _reader: Reader = Reader
  let _file: File
  let _min_read_size: USize
  var _last_line_length: USize = 256
  var _cursor: USize
  var _has_next: Bool

  new create(
    file: File,
    start_position: (USize | None) = None,
    min_read_size: USize = 256) =>
    _file = file
    _cursor =
      match start_position
      | let pos: USize => pos
      | None => _file.position()
      end
    _min_read_size = min_read_size
    _has_next = _file.valid()

  fun ref has_next(): Bool =>
    _has_next

  fun ref next(): String iso^ ? =>
    """
    next:
      set _has_next to false iff:

    while loop exit condition:

    """
    while true do
      try
        return _read_line()?
      else
        if not _fill_buffer() then
          // nothing to read from file, we can savely exit here
          break
        end
      end
    end
    _has_next = false
    if _reader.size() > 0 then
      // don't forget the last line
      _read_last_line()?
    else
      // nothing to return, we can only error here
      error
    end

  fun ref _read_line(): String iso^ ? =>
    let line = _reader.line()?
    _last_line_length = line.size()
    consume line

  fun ref _fill_buffer(): Bool =>
    """
    read from file and fill the reader-buffer.

    Returns `true` if data could be read from the file.

    After a successful reading operation `_cursor` is updated.
    """
    var result = true
    // get back to position of last line
    let current_pos = _file.position()
    _file.seek_start(_cursor)
    if _file.valid() then
      let read_bytes = _last_line_length.max(_min_read_size)
      let read_buf = _file.read(read_bytes)
      _cursor = _file.position()

      let errno = _file.errno()
      if (read_buf.size() == 0) and (errno isnt FileOK) then
        result = false
      else
        // TODO: Limit size of read buffer
        _reader.append(consume read_buf)
      end
    else
      result = false
    end
    // reset position to not disturb other operations on the file
    _file.seek_start(current_pos)
    result

  fun ref _read_last_line(): String iso^ ? =>
    let block = _reader.block(_reader.size())?
    String.from_iso_array(consume block)



