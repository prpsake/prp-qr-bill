type errorCorrectionLevel = 
  [
    #L 
  | #M 
  | #Q
  | #H 
  ]



type pathDataOptions = {
  ecl: errorCorrectionLevel,
  width: int,
  height: int,
  padding: int
}



let pathDataFromString: string => pathDataOptions => string