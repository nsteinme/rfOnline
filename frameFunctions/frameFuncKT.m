

function [frameTimes, allFrames] = frameFuncKT(syncT, syncDat, mouseName, thisDate, expNum)

syncFlips = schmittTimes(syncT, syncDat, [-1.75 -1.25]);

