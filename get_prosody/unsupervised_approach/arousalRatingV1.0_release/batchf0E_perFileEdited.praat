input_file$ = "subject.wav"
output_file$ = "../ADOS/prosody_subtasks/src/arousal/featss/.///2011_06_29-3153/aud_rawVAD/subject/3153-blu2_l_subject_266.wav.txt"
# This Praat script extracts pitch and intensity for every 10ms
# This code is a lot based on the one written by Setsuko Shirai
#input_file$ = "/Users/DannyBone/Desktop/tempdir.wav"
#output_file$ = "/Users/DannyBone/Desktop/tempdir.txt"
# Parameter setting section-----------------------
type_file$ = "wav"
# Parameter setting section-----------------------
type_file$ = "wav"
# Pitch (ac) parameters (detailed parameter setting)
# male: 75-300, female: 100-600 in my database.
minimum_pitch = 75
maximum_pitch = 450
max_num_candidate = 15
sil_thld = 0.04
vo_thld = 0.45
octv_cost = 0.01
octv_jump_cost = 0.70
v_uv_cost = 0.18
win_length =0.025
win_shift = 0.010
# finding files we are looking for
Read from file... 'input_file$'
# change the name of each file - for batch processing
select all
currSoundID = selected ("Sound", 1)
select 'currSoundID'
i = 1
currName$ = "word_'i'"
Rename... 'currName$'
select Sound word_'i'
# get the finishing time of the Sound file
fTime = Get finishing time
fTime = floor(fTime * 100) / 100
# Use numTimes in the loop
numTimes = fTime / win_shift
newName$ = "word_'i'"
select Sound word_'i'
# 1st argument: Time step (s), 2nd argument: Minimum pitch for Analysis, 
# 3rd argument: Maximum pitch for Analysis
# (1) When Simple pitch extraction
# To Pitch... 'win_shift' 'minimum_pitch' 'maximum_pitch'
# (2) AC pitch extraction: The full names of its arguments are following: 
# time_step min_f0 max_#candidate, Very accurate, Silence Threshold, Voicing Threshold
# Octave cost, Octave-jump cost, Voiced/unvoiced cost, max_f0
To Pitch (ac)... 'win_shift' 'minimum_pitch' 'max_num_candidate' no 'sil_thld' 'vo_thld' 'octv_cost' 'octv_jump_cost' 'v_uv_cost' 'maximum_pitch'
Rename... 'newName$'
# select Sound word_'i'_'new_sample_rate'
select Sound word_'i'
To Intensity... 'minimum_pitch' 0
Create Table... table_word_'i' numTimes 3
Set column label (index)... 1 T
Set column label (index)... 2 F0
Set column label (index)... 3 E
for itime to numTimes
select Pitch word_'i'
curtime = win_shift * itime
f0 = 0
f0 = Get value at time... 'curtime' Hertz Linear
f0$ = fixed$ (f0, 2)
if f0$ = "--undefined--"
f0$ = "0"
endif
curtime$ = fixed$ (curtime, 5)
# select Intensity word_'i'_'new_sample_rate'
select Intensity word_'i'
intensity = Get value at time... 'curtime' Cubic
intensity$ = fixed$ (intensity, 2)
if intensity$ = "--undefined--"
intensity$ = "0"
endif
select Table table_word_'i'
Set numeric value... itime T 'curtime$'
Set numeric value... itime F0 'f0$' 
Set numeric value... itime E  'intensity$'
endfor
select Table table_word_'i'
Write to table file... 'output_file$'
