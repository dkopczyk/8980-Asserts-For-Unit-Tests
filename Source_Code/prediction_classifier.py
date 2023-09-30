import sys

def main(assertLineFilePath, predictionFilePath):
    
    count_perfect = 0
    count_imperfect = 0

    assertLineFile = open(assertLineFilePath, 'r', encoding="utf8")
    predictionFile = open(predictionFilePath, 'r', encoding="utf8")
    
    for line in assertLineFile:
        assertStatement = line.strip()
        predictionLine = predictionFile.readline().strip()
        
        if(assertStatement == predictionLine):
            count_perfect += 1

        else:
            count_imperfect += 1

    assertLineFile.close()
    predictionFile.close()
    
    sys.exit((str(count_perfect) + " " + str(count_imperfect)))

if __name__=="__main__":
    main(sys.argv[1], sys.argv[2])
