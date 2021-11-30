/** 

`removeWhitespace(x)` 

Takes string `x` and returns a string from `x` without whitespace.
Returns an empty string if `x` is not a string.

*/
let removeWhitespace: string => string =
  x =>
  switch Js.Types.classify(x) {
  | JSString(x) => Js.String2.replaceByRe(x, %re("/\s/g"), "")
  | _ => ""
  }



/** 

`reverseStr(x)` 

Takes string `x` and returns a reversed string from `x`.

*/
let reverseStr: string => string =
  x =>
  Js.String2.split(x, "")
  ->Js.Array2.reverseInPlace
  ->Js.Array2.joinWith("")



/**

`blockStr(n, x)`

Takes integer `n`, string `x` and returns a string from `x` grouped in 
character-blocks of maximal length `n` seperated by spaces.
Returns an empty string if `x` is not a string.

Examples: 
- n = 3, x = "123456789" ->"123 456 789"
- n = 4, x = "abcdefghi" ->"abcd efgh i"
- n = 5, x = "xxxx" ->"xxxx"

*/
let blockStr: int => string => string =
  n =>
  x =>
  switch Js.Types.classify(x) {
  | JSString(x) => 
    let pat = Js.Re.fromStringWithFlags("\\S{"++Belt.Int.toString(n)++"}", ~flags="g")
    removeWhitespace(x)
    ->Js.String2.replaceByRe(pat, "$& ")
    ->Js.String2.trim
  | _ => ""
  }



let blockStr3 = blockStr(3)
let blockStr4 = blockStr(4)
let blockStr5 = blockStr(5)
let blockStrRight3: string => string =
  x =>
  reverseStr(x)
  ->blockStr3
  ->reverseStr



/**

referenceBlockStr(x)

Takes string `x`, if `x` starts with "RF", returns a string from `x` in 
the Creditor Reference format (CROOKS 11649), else returns a string from `x` 
in the QR-Reference format.
Returns an empty string if `x` is not a string.

Examples:
- x = "RF18539007547034" ->"RF18 5390 0754 7034"
- x = "213455654786322980076652786" ->"21 34556 54786 32298 00766 52786"

*/
let referenceBlockStr: string => string =
  x =>
  switch Js.Types.classify(x) {
  | JSString(x) =>
    let xTrim = Js.String2.trim(x)
    Js.String2.startsWith(xTrim, "RF") ?
    blockStr4(xTrim) :
    Js.String2.substring(xTrim, ~from=0, ~to_=2)
    ++" "
    ++blockStr5(Js.String2.substringToEnd(xTrim, ~from=2))
  | _ => ""
  }



/**

moneyFromNumberStr(n, x)

Takes integer `n`, string `x` and returns a float string from `x` with
precision `n`, where wholes are grouped in 3-character-blocks from the right.
Returns an empty string if `x` is not a string or not parsable to float.

*/
let moneyFromNumberStr: int => string => string =
  n =>
  x =>
  switch Js.Types.classify(x) {
  | JSString(x) =>
    removeWhitespace(x)
    ->Js.Float.fromString
    ->Js.Float.toFixedWithPrecision(~digits=n)
    ->Js.String2.split(".")
    ->units =>
      switch Js.Array2.length(units) {
      | 1 => blockStrRight3(units[0])++ "." ++Js.String2.repeat("0", n)
      | 2 => blockStrRight3(units[0])++ "." ++units[1]
      | _ => ""
      }
  | _ => ""
  }



let moneyFromNumberStr2 = moneyFromNumberStr(2)