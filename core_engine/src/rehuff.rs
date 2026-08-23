//! Rebuilds a baseline JPEG's Huffman tables from the file's own symbol counts,
//! which is what `jpegtran -optimize` does.
//!
//! Nothing about the picture changes. Every quantised coefficient is carried over
//! symbol for symbol, so the file decodes to exactly the same pixels; only the
//! code words and the DHT segments that describe them are new. The saving is real
//! all the same, because `image`'s encoder writes the fixed example tables out of
//! the JPEG standard's Annex K - a guess at what an average photo needs, not what
//! this page needs. How much that saves depends on what is on the page and the
//! spread is wide, so no one figure is honest - [`rehuff`] carries the measured
//! range, and a page of small text sits at the thin end of it. What comes out is byte
//! for byte the same file as `jpegtran -optimize -copy all` writes, checked on
//! eleven fixtures from 400x500 to 2480x3508: colour and grey, one block to an
//! MCU and four.
//!
//! The scan is walked twice rather than decoded into coefficients and held: forty
//! pages must not cost forty pages of coefficients. The peak is the input plus the
//! output, and nothing in between.
//!
//! Every check here ends in a sentence rather than a guess, because the only
//! caller falls back to the original bytes. A file this module will not touch
//! costs nothing but the saving.

/// The 64 coefficients of one 8x8 block, in zig-zag order. Position 0 is the DC
/// coefficient, 1 to 63 the AC ones.
const BLOCK_LEN: usize = 64;

/// How many Huffman tables of one class a baseline JPEG may name. Four DC tables
/// and four AC ones.
const CLASS_SLOTS: usize = 4;

/// The eight table slots together. A slot is `class * CLASS_SLOTS + id`, so the
/// four DC tables come first and the four AC tables after them.
const TABLE_SLOTS: usize = CLASS_SLOTS * 2;

/// The longest Huffman code JPEG can express, in bits.
const MOST_CODE_BITS: usize = 16;

/// 256 real symbols plus one that is counted but never written. Reserving it
/// keeps the all-ones code word free, which a decoder is allowed to read past the
/// last block, and it is what libjpeg does.
const SYMBOL_SLOTS: usize = 257;

/// How long a code may grow while the tree is being built, before the lengths are
/// traded back down under [`MOST_CODE_BITS`]. 32 is libjpeg's own limit, and the
/// output has to match libjpeg symbol for symbol.
const MOST_MERGE_BITS: usize = 32;

/// A Huffman table in the two shapes this module needs: the way JPEG stores it,
/// and a lookup for coding.
struct Table {
    /// How many codes of each length 1 to 16, which is what a DHT segment carries.
    counts: [u8; MOST_CODE_BITS],
    /// The symbols in code order, which is the rest of the DHT segment.
    symbols: Vec<u8>,
    /// Code word and length for each of the 256 symbols. A length of 0 means the
    /// symbol is not in this table.
    codes: [(u16, u8); 256],
    /// Figure F.15 of the standard: the smallest and the largest code of each
    /// length, and where that length's symbols start. Entry 0 is never used, so
    /// that a code length can be the index itself.
    min_code: [i32; MOST_CODE_BITS + 1],
    max_code: [i32; MOST_CODE_BITS + 1],
    val_ptr: [usize; MOST_CODE_BITS + 1],
}

impl Table {
    /// Builds the coding lookups from the two things a DHT segment holds.
    ///
    /// - Parameters:
    ///   counts: How many codes of each length 1 to 16.
    ///   symbols: The symbols in code order.
    /// - Returns:
    ///   The table, or a sentence saying the counts and the symbols do not agree,
    ///   or that the counts ask for more codes than their lengths can hold.
    fn new(counts: [u8; MOST_CODE_BITS], symbols: Vec<u8>) -> Result<Self, String> {
        let total: usize = counts.iter().map(|count| *count as usize).sum();
        if total != symbols.len() {
            return Err(format!(
                "A Huffman table says it holds {total} symbols but {} follow it.",
                symbols.len()
            ));
        }

        let mut codes = [(0u16, 0u8); 256];
        let mut min_code = [0i32; MOST_CODE_BITS + 1];
        let mut max_code = [-1i32; MOST_CODE_BITS + 1];
        let mut val_ptr = [0usize; MOST_CODE_BITS + 1];
        let mut code = 0u32;
        let mut next = 0usize;
        for len in 1..=MOST_CODE_BITS {
            // len runs 1..=16. `counts` holds 16 entries, so `len - 1` is inside
            // it; the other three hold 17, so `len` is inside them.
            let count = counts[len - 1] as usize;
            val_ptr[len] = next;
            min_code[len] = code as i32;
            for _ in 0..count {
                if code > u16::MAX as u32 {
                    return Err(
                        "A Huffman table holds more codes than its lengths allow.".to_string()
                    );
                }
                let symbol = match symbols.get(next) {
                    Some(symbol) => *symbol as usize,
                    None => return Err("A Huffman table ran out of symbols.".to_string()),
                };
                // `symbol` came out of a u8, and `codes` holds 256 entries.
                codes[symbol] = (code as u16, len as u8);
                code += 1;
                next += 1;
            }
            max_code[len] = if count == 0 { -1 } else { code as i32 - 1 };
            code <<= 1;
        }

        Ok(Table {
            counts,
            symbols,
            codes,
            min_code,
            max_code,
            val_ptr,
        })
    }
}

/// Reads single bits out of an entropy coded scan, stepping over the zero byte
/// JPEG stuffs after every 0xFF.
struct BitReader<'a> {
    data: &'a [u8],
    at: usize,
    byte: u32,
    held: u8,
}

impl<'a> BitReader<'a> {
    fn new(data: &'a [u8]) -> Self {
        BitReader {
            data,
            at: 0,
            byte: 0,
            held: 0,
        }
    }

    /// The next bit, most significant first.
    ///
    /// - Returns:
    ///   The bit, or a sentence saying the scan stopped short or holds a marker
    ///   where coded bits should be.
    fn bit(&mut self) -> Result<u32, String> {
        if self.held == 0 {
            let byte = match self.data.get(self.at) {
                Some(byte) => *byte,
                None => return Err("The scan ends in the middle of a block.".to_string()),
            };
            self.at += 1;
            if byte == 0xFF {
                match self.data.get(self.at) {
                    Some(0x00) => self.at += 1,
                    _ => return Err("A marker appears inside the scan.".to_string()),
                }
            }
            self.byte = byte as u32;
            self.held = 8;
        }
        self.held -= 1;
        Ok((self.byte >> self.held) & 1)
    }

    /// The next `count` bits as one number.
    ///
    /// - Parameters:
    ///   count: How many bits to take. Never more than 16, so the result fits.
    /// - Returns:
    ///   The bits, or the sentence [`BitReader::bit`] gives.
    fn bits(&mut self, count: u8) -> Result<u32, String> {
        let mut out = 0u32;
        for _ in 0..count {
            out = (out << 1) | self.bit()?;
        }
        Ok(out)
    }

    /// The next Huffman symbol, read one bit at a time as Figure F.16 describes.
    ///
    /// - Parameters:
    ///   table: The table the scan header named for this symbol.
    /// - Returns:
    ///   The symbol, or a sentence saying the code is not in the table.
    fn symbol(&mut self, table: &Table) -> Result<u8, String> {
        let mut code = self.bit()? as i32;
        for len in 1..=MOST_CODE_BITS {
            // len runs 1..=16 over arrays of 17 entries.
            //
            // The second test is what keeps the subtraction below from going
            // negative: a canonical table always has min_code <= code once
            // max_code >= code, but a table read out of a broken file need not.
            if table.max_code[len] >= code && code >= table.min_code[len] {
                // The difference is at most the number of codes of this length,
                // so under 256, and val_ptr is at most 256: no overflow.
                let index = table.val_ptr[len] + (code - table.min_code[len]) as usize;
                return match table.symbols.get(index) {
                    Some(symbol) => Ok(*symbol),
                    None => Err("A Huffman code points past the end of its table.".to_string()),
                };
            }
            code = (code << 1) | self.bit()? as i32;
        }
        Err("A Huffman code in the scan is longer than 16 bits.".to_string())
    }
}

/// Writes bits back out, stuffing a zero byte after every 0xFF so no code word
/// can look like a marker.
struct BitWriter {
    out: Vec<u8>,
    held_bits: u32,
    held: u8,
}

impl BitWriter {
    fn new(out: Vec<u8>) -> Self {
        BitWriter {
            out,
            held_bits: 0,
            held: 0,
        }
    }

    /// Appends the low `len` bits of `code`.
    ///
    /// `len` is never more than 16: a Huffman code is capped at
    /// [`MOST_CODE_BITS`], a DC symbol is refused above 16 extra bits, and an AC
    /// symbol's bit count is a nibble. With at most 7 bits still held that keeps
    /// the accumulator under 24 of its 32 bits, so neither shift can lose one.
    fn put(&mut self, code: u32, len: u8) {
        if len == 0 {
            return;
        }
        self.held_bits = (self.held_bits << len) | (code & ((1u32 << len) - 1));
        self.held += len;
        while self.held >= 8 {
            self.held -= 8;
            let byte = ((self.held_bits >> self.held) & 0xFF) as u8;
            self.out.push(byte);
            if byte == 0xFF {
                self.out.push(0x00);
            }
        }
    }

    /// Pads the last byte with one bits, the way libjpeg does, and gives the
    /// buffer back.
    fn finish(mut self) -> Vec<u8> {
        if self.held > 0 {
            let pad = 8 - self.held;
            self.put((1u32 << pad) - 1, pad);
        }
        self.out
    }
}

/// One component of the frame, as SOF0 and SOS together describe it.
struct Component {
    /// How many blocks of this component sit across and down one MCU.
    h: u8,
    v: u8,
    /// Which of the eight table slots carries its DC and its AC symbols.
    dc: usize,
    ac: usize,
}

/// The frame as SOF0 describes it: its components, and how many MCUs the scan
/// holds across and down.
struct Frame {
    comps: Vec<Component>,
    mcus_x: usize,
    mcus_y: usize,
}

/// What a walk over the scan does with each symbol it meets.
enum Sink<'a> {
    /// Pass one: add the symbol to its table's counts.
    Count(&'a mut [[u64; SYMBOL_SLOTS]; TABLE_SLOTS]),
    /// Pass two: write the symbol out with the new tables.
    Write(&'a mut BitWriter, &'a [Option<Table>; TABLE_SLOTS]),
}

impl Sink<'_> {
    /// Takes one symbol and the raw bits that follow it.
    ///
    /// - Parameters:
    ///   slot: Which of the eight tables the symbol belongs to.
    ///   symbol: The Huffman symbol itself.
    ///   extra: The raw bits that follow the symbol.
    ///   extra_len: How many of those bits there are.
    /// - Returns:
    ///   Nothing, or a sentence saying the new tables have no code for this
    ///   symbol - which would drop it from the scan without a sound.
    fn feed(&mut self, slot: usize, symbol: u8, extra: u32, extra_len: u8) -> Result<(), String> {
        match self {
            // Both slot numbers were checked against CLASS_SLOTS while the frame
            // and scan headers were read, so `slot` is one of the eight in either
            // array. `symbol` came out of a u8, so it is inside the 257 counts and
            // inside the 256 codes alike.
            Sink::Count(counted) => {
                counted[slot][symbol as usize] += 1;
                Ok(())
            }
            Sink::Write(writer, tables) => {
                let (code, len) = match &tables[slot] {
                    Some(table) => table.codes[symbol as usize],
                    None => {
                        return Err("The scan needs a table the new set does not hold.".to_string())
                    }
                };
                if len == 0 {
                    return Err("A symbol in the scan has no code in the new table.".to_string());
                }
                writer.put(code as u32, len);
                writer.put(extra, extra_len);
                Ok(())
            }
        }
    }
}

/// Walks every block of the scan once, handing each symbol to the sink.
///
/// The DC coefficient is stored as a difference from the block before it, and
/// this never adds those differences up: the symbol and its raw bits are carried
/// over as they are, so the coefficient the decoder rebuilds is untouched.
///
/// - Parameters:
///   scan: The entropy coded bytes, starting right after the scan header.
///   frame: The components and the MCU counts out of SOF0 and SOS.
///   read_with: The file's own tables, which is what the scan is coded in.
///   sink: Counts the symbols, or writes them with the new tables.
/// - Returns:
///   Nothing, or a sentence saying what the scan does that this cannot read.
fn walk_scan(
    scan: &[u8],
    frame: &Frame,
    read_with: &[Option<Table>; TABLE_SLOTS],
    sink: &mut Sink,
) -> Result<(), String> {
    let mut reader = BitReader::new(scan);
    for _ in 0..frame.mcus_y {
        for _ in 0..frame.mcus_x {
            for comp in frame.comps.iter() {
                // Both slots were checked against CLASS_SLOTS while the headers
                // were read, so they are inside the eight.
                let dc_table = match &read_with[comp.dc] {
                    Some(table) => table,
                    None => {
                        return Err("The scan names a DC table the page never sent.".to_string())
                    }
                };
                let ac_table = match &read_with[comp.ac] {
                    Some(table) => table,
                    None => {
                        return Err("The scan names an AC table the page never sent.".to_string())
                    }
                };
                for _ in 0..(comp.h as usize * comp.v as usize) {
                    // DC: one symbol saying how many raw bits carry the difference.
                    let size = reader.symbol(dc_table)?;
                    if size as usize > MOST_CODE_BITS {
                        return Err("A DC symbol asks for more than 16 bits.".to_string());
                    }
                    let extra = reader.bits(size)?;
                    sink.feed(comp.dc, size, extra, size)?;

                    // AC: how many zeroes to skip in the high nibble, how many raw
                    // bits follow in the low one.
                    let mut position = 1usize;
                    while position < BLOCK_LEN {
                        let run_size = reader.symbol(ac_table)?;
                        let run = (run_size >> 4) as usize;
                        let size = run_size & 0x0F;
                        if size == 0 {
                            sink.feed(comp.ac, run_size, 0, 0)?;
                            // A run of 15 with no value is "skip sixteen zeroes";
                            // anything else with no value ends the block.
                            if run == 15 {
                                position += 16;
                                continue;
                            }
                            break;
                        }
                        let extra = reader.bits(size)?;
                        sink.feed(comp.ac, run_size, extra, size)?;
                        position += run + 1;
                    }
                }
            }
        }
    }
    Ok(())
}

/// Makes every symbol already joined to `start` one bit longer, and gives back
/// the far end of that chain.
fn lengthen(
    start: usize,
    others: &[i32; SYMBOL_SLOTS],
    codesize: &mut [u16; SYMBOL_SLOTS],
) -> usize {
    let mut walk = start;
    // `start` came out of an index into an array of SYMBOL_SLOTS, and `others`
    // only ever holds such an index, so `walk` never leaves either array. A
    // symbol is joined at most 256 times, so the count cannot run past a u16.
    codesize[walk] += 1;
    while others[walk] >= 0 {
        walk = others[walk] as usize;
        codesize[walk] += 1;
    }
    walk
}

/// Turns symbol counts into the shortest code lengths JPEG can express, the way
/// libjpeg's `jpeg_gen_optimal_table` does, so the table comes out the same as
/// `jpegtran -optimize` writes it.
///
/// - Parameters:
///   counted: How often each symbol appears in the scan.
/// - Returns:
///   The table, or a sentence saying the counts need codes this format cannot
///   carry.
fn optimal_table(counted: &[u64; SYMBOL_SLOTS]) -> Result<Table, String> {
    let mut freq = *counted;
    // The reserved symbol, given a count of one so it takes part in the tree and
    // keeps the all-ones code word out of real use. It is the last of the
    // SYMBOL_SLOTS entries, so the index is inside `freq` by construction.
    freq[SYMBOL_SLOTS - 1] = 1;
    let mut others = [-1i32; SYMBOL_SLOTS];
    let mut codesize = [0u16; SYMBOL_SLOTS];

    // Huffman's own method: join the two rarest symbols over and over. Ties go to
    // the higher symbol, because that is the order libjpeg scans in and the table
    // has to come out the same.
    loop {
        let mut rarest = -1i32;
        let mut rarest_count = u64::MAX;
        for (symbol, count) in freq.iter().enumerate() {
            if *count > 0 && *count <= rarest_count {
                rarest_count = *count;
                rarest = symbol as i32;
            }
        }
        let mut second = -1i32;
        let mut second_count = u64::MAX;
        for (symbol, count) in freq.iter().enumerate() {
            if *count > 0 && *count <= second_count && symbol as i32 != rarest {
                second_count = *count;
                second = symbol as i32;
            }
        }
        if second < 0 {
            break;
        }

        // Both came out of an index into `freq`, which is SYMBOL_SLOTS long, and
        // so are `others` and `codesize`.
        let (first, other) = (rarest as usize, second as usize);
        freq[first] += freq[other];
        freq[other] = 0;
        let tail = lengthen(first, &others, &mut codesize);
        others[tail] = other as i32;
        lengthen(other, &others, &mut codesize);
    }

    // How many codes each length ended up with. A code longer than 32 bits is
    // refused rather than trimmed: nothing this module writes should be a guess.
    let mut lengths = [0u32; MOST_MERGE_BITS + 1];
    for size in codesize.iter() {
        if *size == 0 {
            continue;
        }
        match lengths.get_mut(*size as usize) {
            Some(count) => *count += 1,
            None => {
                return Err("A symbol on this page needs a code longer than 32 bits.".to_string())
            }
        }
    }

    // Trade everything longer than 16 bits back down, the way Annex K does it:
    // two of the longest codes give up their place and a shorter one becomes a
    // prefix instead of a symbol.
    for len in (MOST_CODE_BITS + 1..=MOST_MERGE_BITS).rev() {
        // len runs 32 down to 17 over an array of 33 entries, so len and len - 1
        // are both inside it.
        while lengths[len] > 0 {
            // The deepest level of a Huffman tree always holds an even number of
            // symbols, so there are always two to trade. Checked all the same,
            // because a count that wrapped would build a table nobody can decode.
            if lengths[len] < 2 {
                return Err("The code lengths on this page cannot be traded down.".to_string());
            }
            // `prefix` starts at len - 2, so between 15 and 30, and only ever
            // falls, so it and prefix + 1 both stay inside the 33 entries.
            let mut prefix = len - 2;
            while lengths[prefix] == 0 {
                if prefix == 0 {
                    return Err(
                        "The code lengths on this page cannot be brought under 16 bits."
                            .to_string(),
                    );
                }
                prefix -= 1;
            }
            lengths[len] -= 2;
            lengths[len - 1] += 1;
            lengths[prefix + 1] += 2;
            lengths[prefix] -= 1;
        }
    }

    // Give the reserved code point back. It was counted so the tree would leave
    // the all-ones word free, but it is not one of the symbols written out.
    let mut longest = MOST_CODE_BITS;
    // `longest` starts at 16 and only falls, so it stays inside the 33 entries.
    while lengths[longest] == 0 {
        if longest == 0 {
            return Err("A Huffman table for this page came out empty.".to_string());
        }
        longest -= 1;
    }
    lengths[longest] -= 1;

    let mut counts = [0u8; MOST_CODE_BITS];
    for len in 1..=MOST_CODE_BITS {
        // len runs 1..=16: inside `lengths` at 33 entries, and `len - 1` inside
        // `counts` at 16.
        if lengths[len] > u8::MAX as u32 {
            return Err(
                "A Huffman table for this page needs more than 255 codes of one length."
                    .to_string(),
            );
        }
        counts[len - 1] = lengths[len] as u8;
    }

    // The symbols go out sorted by the length they had *before* the trading, which
    // is why this counts past 16. That order is what makes the table match the one
    // jpegtran writes byte for byte.
    let mut symbols = Vec::new();
    for len in 1..=MOST_MERGE_BITS as u16 {
        // `take(256)` leaves out the reserved symbol, which is never written.
        for (symbol, size) in codesize.iter().enumerate().take(256) {
            if *size == len {
                symbols.push(symbol as u8);
            }
        }
    }

    Table::new(counts, symbols)
}

/// Reads the tables out of one DHT segment into their slots.
///
/// - Parameters:
///   body: The segment without its marker and its length.
///   tables: The eight slots, filled in place.
/// - Returns:
///   Nothing, or a sentence saying the segment stops short or names a table a
///   baseline JPEG cannot have.
fn read_tables(body: &[u8], tables: &mut [Option<Table>; TABLE_SLOTS]) -> Result<(), String> {
    let truncated = || "A Huffman table segment of the page stops short.".to_string();
    let mut at = 0usize;
    while at < body.len() {
        let (class, id) = match body.get(at) {
            Some(byte) => ((*byte >> 4) as usize, (*byte & 0x0F) as usize),
            None => return Err(truncated()),
        };
        if class > 1 || id >= CLASS_SLOTS {
            return Err("The page names a Huffman table a baseline JPEG cannot have.".to_string());
        }
        let mut counts = [0u8; MOST_CODE_BITS];
        match body.get(at + 1..at + 1 + MOST_CODE_BITS) {
            Some(read) => counts.copy_from_slice(read),
            None => return Err(truncated()),
        }
        let total: usize = counts.iter().map(|count| *count as usize).sum();
        let symbols_at = at + 1 + MOST_CODE_BITS;
        let symbols = match body.get(symbols_at..symbols_at + total) {
            Some(read) => read.to_vec(),
            None => return Err(truncated()),
        };
        // `class` is 0 or 1 and `id` is under four, so the slot is one of the
        // eight. The slot always moves on by at least 17, so this loop ends.
        tables[class * CLASS_SLOTS + id] = Some(Table::new(counts, symbols)?);
        at = symbols_at + total;
    }
    Ok(())
}

/// Reads the size and the sampling factors out of the SOF0 segment.
///
/// - Parameters:
///   body: The segment without its marker and its length.
/// - Returns:
///   The frame, or a sentence saying the header stops short or describes a frame
///   that has no blocks to walk.
fn read_frame(body: &[u8]) -> Result<Frame, String> {
    let truncated = || "The frame header of the page stops short.".to_string();
    let height = match (body.get(1), body.get(2)) {
        (Some(high), Some(low)) => ((*high as usize) << 8) | *low as usize,
        _ => return Err(truncated()),
    };
    let width = match (body.get(3), body.get(4)) {
        (Some(high), Some(low)) => ((*high as usize) << 8) | *low as usize,
        _ => return Err(truncated()),
    };
    let count = match body.get(5) {
        Some(count) => *count as usize,
        None => return Err(truncated()),
    };
    if width == 0 || height == 0 || count == 0 {
        return Err("The page's frame header gives no size or no component.".to_string());
    }

    let mut comps = Vec::with_capacity(count);
    let mut widest = 1usize;
    let mut tallest = 1usize;
    for index in 0..count {
        // `count` came out of a u8, so the offset is at most 7 + 254 * 3.
        let sampling = match body.get(7 + index * 3) {
            Some(byte) => *byte,
            None => return Err(truncated()),
        };
        let (h, v) = (sampling >> 4, sampling & 0x0F);
        if h == 0 || v == 0 {
            return Err("A component of the page samples nothing.".to_string());
        }
        widest = widest.max(h as usize);
        tallest = tallest.max(v as usize);
        comps.push(Component {
            h,
            v,
            dc: 0,
            ac: CLASS_SLOTS,
        });
    }

    // One MCU is `widest` by `tallest` blocks of 8x8 pixels, and a part of an MCU
    // at the right or the bottom edge is still coded whole, which is what the
    // rounding up is for.
    Ok(Frame {
        comps,
        mcus_x: width.div_ceil(widest * 8),
        mcus_y: height.div_ceil(tallest * 8),
    })
}

/// Reads which two tables each component's symbols are coded with out of the SOS
/// segment.
///
/// - Parameters:
///   body: The segment without its marker and its length.
///   comps: The frame's components, filled in place.
/// - Returns:
///   Nothing, or a sentence saying the header stops short, or describes a scan
///   that is not the one whole baseline scan this module reads.
fn read_scan_header(body: &[u8], comps: &mut [Component]) -> Result<(), String> {
    let truncated = || "The scan header of the page stops short.".to_string();
    let count = match body.first() {
        Some(count) => *count as usize,
        None => return Err(truncated()),
    };
    if count != comps.len() {
        return Err("The page's scan does not cover every component of its frame.".to_string());
    }
    for (index, comp) in comps.iter_mut().enumerate() {
        // `index` is under `count`, which came out of a u8, so the offset is at
        // most 2 + 254 * 2.
        let slots = match body.get(2 + index * 2) {
            Some(byte) => *byte,
            None => return Err(truncated()),
        };
        let (dc, ac) = ((slots >> 4) as usize, (slots & 0x0F) as usize);
        if dc >= CLASS_SLOTS || ac >= CLASS_SLOTS {
            return Err(
                "The page's scan names a Huffman table a baseline JPEG cannot have.".to_string(),
            );
        }
        comp.dc = dc;
        comp.ac = CLASS_SLOTS + ac;
    }
    // A baseline scan carries the whole block, coefficient 0 to 63, in one go.
    // Anything narrower is a progressive pass wearing a baseline header.
    match (body.get(1 + count * 2), body.get(2 + count * 2)) {
        (Some(0), Some(63)) => Ok(()),
        (Some(_), Some(_)) => Err(
            "The page's scan covers only part of each block, so it is not baseline.".to_string(),
        ),
        _ => Err(truncated()),
    }
}

/// Writes one DHT segment per table the page uses, walking the components of the
/// scan and taking each one's DC table and then its AC table.
///
/// That component order is libjpeg's, and following it is what makes the file
/// this module writes come out byte for byte the same as `jpegtran -optimize`.
/// Every fresh table belongs to some component, because a table is only built
/// from symbols a component fed, so this cannot leave one out.
fn write_tables(frame: &Frame, tables: &[Option<Table>; TABLE_SLOTS], out: &mut Vec<u8>) {
    let mut written = [false; TABLE_SLOTS];
    for comp in frame.comps.iter() {
        for slot in [comp.dc, comp.ac] {
            // Both slots were checked against CLASS_SLOTS while the headers were
            // read, so they are inside the eight of either array.
            if written[slot] {
                continue;
            }
            written[slot] = true;
            if let Some(table) = &tables[slot] {
                // A slot is `class * CLASS_SLOTS + id`, so this takes it apart
                // again. The class and id byte, the 16 counts, then the symbols -
                // at most 273 bytes, plus the two the length counts itself in.
                let class = (slot / CLASS_SLOTS) as u8;
                let id = (slot % CLASS_SLOTS) as u8;
                let body_len = 1 + MOST_CODE_BITS + table.symbols.len();
                out.extend_from_slice(&[0xFF, 0xC4]);
                out.extend_from_slice(&((body_len + 2) as u16).to_be_bytes());
                out.push((class << 4) | id);
                out.extend_from_slice(&table.counts);
                out.extend_from_slice(&table.symbols);
            }
        }
    }
}

/// Rewrites the entropy coding of a baseline JPEG with Huffman tables counted
/// from the page itself.
///
/// The picture does not change: every quantised coefficient is carried over
/// symbol for symbol, so the file decodes to the same pixels, bit for bit. Only
/// the code words and the DHT segments are new, and they come out shorter than
/// the fixed Annex K tables `image`'s encoder writes.
///
/// How much shorter is the page's business, not this module's, and the spread is
/// wide: measured 8 to 13% on a photographed page of text - thirteen real pages,
/// median 10% - 2.5 to 5.0% on grey text, about 16% on grainy paper or a page
/// carrying a photograph, and up to 28% over a mixed 40 page scan - more the
/// noisier the page and the lower the quality (42 to 44% at quality 30). A
/// scanner's usual page is text, so the small end is the one to expect.
/// [`crate::save_page`] carries the numbers.
///
/// The segments go out in libjpeg's own order - APPn, DQT, SOF0, DHT, SOS -
/// because there is no reason to look unusual to a reader with expectations.
/// Everything this module does not rewrite is copied over byte for byte.
///
/// - Parameters:
///   jpeg: A baseline JPEG, as [`crate::save_page`]'s encoder wrote it.
/// - Returns:
///   The smaller file, or a sentence saying what about this one it will not
///   touch: a progressive scan, restart markers, arithmetic coding, a segment
///   that stops short. The caller keeps the original bytes in that case.
pub fn rehuff(jpeg: &[u8]) -> Result<Vec<u8>, String> {
    match (jpeg.first(), jpeg.get(1)) {
        (Some(0xFF), Some(0xD8)) => {}
        _ => return Err("This page does not start with a JPEG marker.".to_string()),
    }

    // The segments are held apart so they can go out in libjpeg's order rather
    // than the order they came in. `head` is everything else, in its own order.
    let mut head: Vec<u8> = Vec::new();
    let mut quant: Vec<u8> = Vec::new();
    let mut frame_bytes: Vec<u8> = Vec::new();
    let mut frame: Option<Frame> = None;
    let mut tables: [Option<Table>; TABLE_SLOTS] = Default::default();
    let mut at = 2usize;

    loop {
        let marker = match (jpeg.get(at), jpeg.get(at + 1)) {
            (Some(0xFF), Some(marker)) => *marker,
            (Some(_), Some(_)) => {
                return Err(format!("Expected a marker at byte {at} of the page."))
            }
            _ => return Err("The page ends before its scan does.".to_string()),
        };
        // These markers carry no segment behind them, so reading a length here
        // would read the picture instead: a second start of image, a restart, or a
        // fill byte all mean this is not the plain baseline file this reads.
        if marker == 0x01 || (0xD0..=0xD8).contains(&marker) {
            return Err("The page holds a marker that cannot stand before a scan.".to_string());
        }
        if marker == 0xD9 {
            return Err("The page ends before it has a scan.".to_string());
        }

        let len = match (jpeg.get(at + 2), jpeg.get(at + 3)) {
            (Some(high), Some(low)) => ((*high as usize) << 8) | *low as usize,
            _ => return Err("A segment of the page has no length.".to_string()),
        };
        // A segment is its two marker bytes and then `len` more, counting the two
        // the length itself sits in.
        let segment = match jpeg.get(at..at + 2 + len) {
            Some(segment) => segment,
            None => return Err("A segment of the page runs past the end of the file.".to_string()),
        };
        // Which also proves `len` is at least 2: a shorter one has no body here.
        let body = match segment.get(4..) {
            Some(body) => body,
            None => return Err("A segment of the page is shorter than its own length.".to_string()),
        };

        match marker {
            // DHT: read, but never copied. New ones are written before the scan.
            0xC4 => read_tables(body, &mut tables)?,
            0xDB => quant.extend_from_slice(segment),
            0xC0 => {
                if frame.is_some() {
                    return Err("The page holds more than one frame header.".to_string());
                }
                frame = Some(read_frame(body)?);
                frame_bytes.extend_from_slice(segment);
            }
            0xDD => {
                return Err(
                    "The page carries restart markers, which this does not read.".to_string(),
                )
            }
            // Every other start of frame is a scan this cannot transcode:
            // progressive, arithmetic coded, lossless, or hierarchical.
            0xC1..=0xCF => {
                return Err("Only a baseline JPEG can have its Huffman tables rebuilt.".to_string())
            }
            0xDA => {
                let mut frame = match frame {
                    Some(frame) => frame,
                    None => {
                        return Err("The page's scan has no frame header before it.".to_string())
                    }
                };
                read_scan_header(body, &mut frame.comps)?;
                let scan = match jpeg.get(at + 2 + len..) {
                    Some(scan) => scan,
                    None => return Err("The page has a scan header but no scan.".to_string()),
                };

                // Pass one: count what this page actually uses.
                let mut counted = [[0u64; SYMBOL_SLOTS]; TABLE_SLOTS];
                walk_scan(scan, &frame, &tables, &mut Sink::Count(&mut counted))?;
                let mut fresh: [Option<Table>; TABLE_SLOTS] = Default::default();
                for (slot, freq) in counted.iter().enumerate() {
                    if freq.iter().any(|count| *count > 0) {
                        // `slot` came out of an enumerate over the eight slots.
                        fresh[slot] = Some(optimal_table(freq)?);
                    }
                }

                let mut out = Vec::with_capacity(jpeg.len());
                out.extend_from_slice(&[0xFF, 0xD8]);
                out.extend_from_slice(&head);
                out.extend_from_slice(&quant);
                out.extend_from_slice(&frame_bytes);
                write_tables(&frame, &fresh, &mut out);
                out.extend_from_slice(segment);

                // Pass two: the same walk again, read with the page's own tables
                // and written with the new ones.
                let mut writer = BitWriter::new(out);
                walk_scan(scan, &frame, &tables, &mut Sink::Write(&mut writer, &fresh))?;
                let mut out = writer.finish();
                out.extend_from_slice(&[0xFF, 0xD9]);
                return Ok(out);
            }
            _ => head.extend_from_slice(segment),
        }
        at += 2 + len;
    }
}
