#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Mar 22 11:40:56 2018

@author: cawatson
"""

import sys
import numpy

assertLineFile = open(sys.argv[1], 'r', encoding="utf8")
predictionFile = open(sys.argv[2], 'r', encoding="utf8")

perfect_predictions = 0
all_potential_predictions = 0
potential_predictions_avg = 0
potential_predictions = []

for line in assertLineFile:
    
    assertLine = line.strip()
    predictionLines = predictionFile.readline().split(" <SEP> ")
    for i in range(len(predictionLines)):
        predictionLines[i] = predictionLines[i].strip()
    
    perfect_pred = False
    count_potential = 0
    
    for i in range(len(predictionLines)):
        if(predictionLines[i] == assertLine):
            perfect_pred = True
        else:
            count_potential += 1

    if(perfect_pred == True):
        perfect_predictions += 1
    potential_predictions.append(count_potential)
    
potential_predictions_avg = numpy.average(numpy.asarray(potential_predictions))
all_potential_predictions = numpy.sum(numpy.asarray(potential_predictions))    

sys.exit((str(perfect_predictions) + " " + str(all_potential_predictions) + " " + str(potential_predictions_avg)))
        
