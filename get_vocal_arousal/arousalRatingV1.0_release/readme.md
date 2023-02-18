############ README ############
Software: Vocal arousal toolkit
Version: 1.0
Author: Daniel Bone
Affiliation: Signal Analysis and Interpretation Laboratory, University of Southern California
Date: 2014
Contact: dbone@usc.edu, sail.usc.edu/~dbone
Overview: This software is designed to extract vocal arousal at the turn-level or at the frame-level (with windowing) from speech data.

**** please cite ****
Daniel Bone, Chi-Chun Lee and Shrikanth S. Narayanan, Robust Unsupervised Arousal Rating: A rule-based framework with knowledge-inspired vocal features (accepted, 2014), in: IEEE Transactions on Affective Computing

other papers using this software:
Daniel Bone, Chi-Chun Lee, Alexandros Potamianos, and Shrikanth Narayanan, "An Investigation of Vocal Arousal Dynamics in Child-Psychologist Interactions using Synchrony Measures and a Conversation-based Model", in Proceedings of InterSpeech, Singapore, 2014.
Daniel Bone, Chi-Chun Lee, and Shrikanth Narayanan, "A Robust Unsupervised Arousal Rating Framework using Prosody with Cross-Corpora Evaluation", in Proceedings of InterSpeech, Portland, OR, USA, 2012.

**** terms of use ****
This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2 dated June, 1991 or at your option any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

**** general operation ****
The software is run with through Matlab with a main .m file, a header file (_main.txt), and possibly additional annotation files. The output is a score file (_scores.txt/csv) in the format score, time. This program requires Praat.exe to run (in Windows there is a version that does not call the GUI). Example main and score files are provided with this software (/examples). There are 3 versions of the program:
1) arousalRating.m
	purpose: single file gets a single vocal arousal rating
	input: main file and required path variables. main file in format: input file, additional path for ouput, neutral, arousal, speaker (e.g., VAM_main.txt)
	output: score, annotated score (e.g., VAM_scores.txt)
	subfunctions: aR_extractFeats, aR_computeScores_pitchLogRaw, aR_computeScores_intensityRaw, aR_computeScores_ltas, aR_fuseScores

2) arousalRating_fullFile.m: 
	purpose: chop a long file into turns and get a rating for each turn (similar to arousalRating.m)
	intput: main file and required path variables. main file in format: input file, additional path for ouput, neutral, arousal, speaker, start time, end time
	output: score, annotated score
	subfunctions: aR_extractFeatsFullFile, aR_computeScores_pitchLogRawFullFile, aR_computeScores_intensityRawFullFile, aR_computeScores_ltasFullFile, aR_fuseScores

3) arousalRatingContinuous.m (experimental): 
	purpose: framewise (10ms) vocal arousal rating with some smoothing
	input: main file and required path variables. main file in format: input file, additional path for ouput, speaker, annotation file (annotation file in format col1: time, col2: arousal)) (e.g., CreativeIT_main.txt)
	output: score, time
	note: only provides continuous ratings that are relative (global normalization), so the absolute values should not be interpreted.
	subfunctions: aR_extractFeats, aRC_computeScores_pitchLogRaw2, aRC_computeScores_intensityRaw2, aRC_computeScores_ltas2, aRC_fuseScores, nanMedFilt, nanMedFiltNan

Other functions:
A) chopWav.m - chops wav by placing Gaussian white noise where a person is not speaking according to the VAD

General Note 1: Each version assumes there is only one speaker per file (as does Praat f0).
General Note 2: If you want to do global speaker normalization (i.e., you don't have neutral affective labels for turns), then set all files as neutral=1. This will give you a relative rating of a speaker's vocal arousal between files or turns, which means that the absolute value may have less meaning. Also remember that the software only works when there are multiple utterances from a single speaker.
General Note 3: If there are no annotations, any value can be inserted in the "arousal" spot of the main.