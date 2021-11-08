/*

Links:
https://www.paymentstandards.ch/dam/downloads/ig-qr-bill-en.pdf#page=39

*/

type errorCorrectionLevel =
  [
    #L
  | #M
  | #Q
  | #H
  ]



type codeOptions = {
  content: string,
  ecl: errorCorrectionLevel,
  width: int,
  height: int,
  padding: int
}



type pathDataOptions = {
  ecl: errorCorrectionLevel,
  width: int,
  height: int,
  padding: int
}



type code = {
  pathData: (. unit) => string
}



@module("./vendor/qrcode-svg")
@new
external code: codeOptions => code = "QRCode"



let pathDataFromString: string => pathDataOptions => string =
  content =>
  options =>
  code({
    content,
    ecl: options.ecl,
    width: options.width,
    height: options.height,
    padding: options.padding
  }).pathData(.)