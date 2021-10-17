type entry = (string, string)



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



let stringFromEntries: array<entry> => string
let pathDataFromString: string => pathDataOptions => string