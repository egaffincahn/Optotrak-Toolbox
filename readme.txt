
#####################################
### Once in a while: OptoCalibEnv ###
#####################################


~~~ want OptoCalibEnvAlign ~~~
OptoCalibEnvAlign does everything the Env does, plus more. Once it's all done, should delete the Evn, and then call the EnvAlign one just Env.
~~~

Any time the vertical position of the table, mirror, projection screen, or projector moves, use OptoCalibEnv. Also needs to be re-run in case of change of screen (projection) resolution. This runs regardless of the Optotrak alignment.

It draws calibration locations in PsychToolbox, to which you align the one connected marker. It creates a mapping between the Optotrak's Cartesian coordinate system to the PsychToolbox space.

Saves the transformation matrix and anonymous function for mapping from Optotrak to PsychToolbox.

#########################################
### Once per session: OptoCalibFinger ###
#########################################

OptoCalibFinger is for determining the fingertip position given the 6-marker wing. Therefore, it needs to be run each time the wing is put back on the finger or moved.

It has two steps: Placing a single marker on the table and measuring its positions, followed by re-initializing the Optotrak system with the wing connected. The participant places their fingertip on the same marker (which is no longer connected). Larry Maloney's scripts do the transformation.

####################################
### Every time loop: OptoCollect ###
####################################

OptoCollect is used to collect data. If you provide the beta coefficients (output from FindFingertip), it will return the fingertip position. If you provide the PsychToolbox transformation matrix, it will provide the PsychToolbox coordinates.

Use:
calib = OptoCalibFinger;
# trial loop
    # time loop
        [xyz, ptb, missing] = OptoCollect(coll, calib.Bcoeffs, calib.Mptb);
        # save xyz
        # draw ptb

