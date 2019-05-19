/*****************************************************************
Name:             SAMPLE.C

Description:

    Optotrak Sample Program.

	- Initiate communications with the Optotrak System.
	- Set additional processing flags to do data conversions on the host computer.
	- Load the appropriate camera parameters.
	- Set up an Optotrak collection.
	- Activate the markers.
	- Request/receive/display 1000 frames of real-time 3D data.
	- De-activate the markers.
	- Disconnect from the Optotrak System.

*****************************************************************/

/*****************************************************************
C Library Files Included
*****************************************************************/
#include <stdio.h>
#include <stdlib.h>

#ifdef _MSC_VER
#include <string.h>
void sleep( unsigned int uSec );
#elif __BORLANDC__
#include <dos.h>
#elif __WATCOMC__
#include <dos.h>
#endif

/*****************************************************************
ND Library Files Included
*****************************************************************/
#include "ndtypes.h"
#include "ndpack.h"
#include "ndopto.h"

/*****************************************************************
Application Files Included
*****************************************************************/
#include "ot_aux.h"

/*****************************************************************
Defines:
*****************************************************************/
#define NUM_FRAMES		1500

#define MARKERS_PORT1	2
#define MARKERS_PORT2	0
#define MARKERS_PORT3	0
#define MARKERS_PORT4	0
#define NUM_MARKERS		MARKERS_PORT1 + MARKERS_PORT2 + MARKERS_PORT3 + MARKERS_PORT4
#define MAXGAP 20

/*****************************************************************
Name:               main

Input Values:
    int
        argc        :Number of command line parameters.
    unsigned char
        *argv[]     :Pointer array to each parameter.

Output Values:
    None.

Return Value:
    None.

Description:

    Main program routine performs all steps listed in the above
    program description.

*****************************************************************/
void main( int argc, unsigned char *argv[] )
{
	int
		gap = 0;  /* used for storing difference between current & previous framenumber */

    unsigned int
        uFlags,
        uElements,
        uFrameCnt,
        uFrameNumber,
		uGapFrequency[MAXGAP + 3],
		i,
		uPreviousFrameNumber;
		
    static Position3d
        p3dData[NUM_MARKERS];
    char
		szLine[100],
        szNDErrorString[MAX_ERROR_STRING_LENGTH + 1];

	/*
	 * Announce that the program has started
	 */
	fprintf( stdout, "\nOptotrak sample program \n\n" );

	/*
	 * look for the -nodld parameter that indicates 'no download'
	 */
	if( ( argc < 2 ) || ( strncmp( argv[1], "-nodld", 6 ) != 0 ) )
	{
		/*
		 * Load the system of processors.
		 */
		fprintf( stdout, "...TransputerLoadSystem\n" );
		if( TransputerLoadSystem( "system" ) != OPTO_NO_ERROR_CODE )
		{
			goto ERROR_EXIT;
		} /* if */

		sleep( 1 );
	} /* if */

	/* 
	 * Pause program to allow the priority of the application to manually be set
	 * to Realtime in the Window 2K Task Manager Processes option.
	 */
	fprintf( stderr, "Press <ENTER> to continue\n" );
	fgets( szLine, sizeof(szLine), stdin );

    /*
     * Wait one second to let the system finish loading.
     */
    sleep( 1 );

    /*
     * Initialize the processors system.
     */
	fprintf( stdout, "...TransputerInitializeSystem\n" );
    if( TransputerInitializeSystem( OPTO_LOG_ERRORS_FLAG ) )

    {
        goto ERROR_EXIT;
    } /* if */

    /*
     * Set optional processing flags (this overides the settings in Optotrak.INI).
     */
	fprintf( stdout, "...OptotrakSetProcessingFlags\n" );
    if( OptotrakSetProcessingFlags( OPTO_LIB_POLL_REAL_DATA |
                                    OPTO_CONVERT_ON_HOST |
                                    OPTO_RIGID_ON_HOST ) )
    {
        goto ERROR_EXIT;
    } /* if */

    /*
     * Load the standard camera parameters.
     */
	fprintf( stdout, "...OptotrakLoadCameraParameters\n" );
    if( OptotrakLoadCameraParameters( "standard" ) )
    {
        goto ERROR_EXIT;
    } /* if */

	/*
	 * Set the strober port table
	 */
	fprintf( stdout, "...OptotrakSetStroberPortTable\n" );
	if( OptotrakSetStroberPortTable( MARKERS_PORT1, MARKERS_PORT2, MARKERS_PORT3, MARKERS_PORT4 ) )
	{
		goto ERROR_EXIT;
	} /* if */

    /*
     * Set up a collection for the Optotrak.
     */
	fprintf( stdout, "...OptotrakSetupCollection\n" );
    if( OptotrakSetupCollection(
            NUM_MARKERS,    /* Number of markers in the collection. */
            (float)150.0,   /* Frequency to collect data frames at. */
            (float)4600.0,  /* Marker frequency for marker maximum on-time. */
            30,             /* Dynamic or Static Threshold value to use. */
            160,            /* Minimum gain code amplification to use. */
            0,              /* Stream mode for the data buffers. */
            (float)0.35,    /* Marker Duty Cycle to use. */
            (float)6.5,     /* Voltage to use when turning on markers. */
            (float)2.0,     /* Number of seconds of data to collect. */
            (float)0.0,     /* Number of seconds to pre-trigger data by. */
            OPTOTRAK_NO_FIRE_MARKERS_FLAG | OPTOTRAK_BUFFER_RAW_FLAG | OPTOTRAK_GET_NEXT_FRAME_FLAG ) )
    {
        goto ERROR_EXIT;
    } /* if */

    /*
     * Wait one second to let the camera adjust.
     */
    sleep( 1 );

    /*
     * Activate the markers.
     */
	fprintf( stdout, "...OptotrakActivateMarkers\n" );
    if( OptotrakActivateMarkers() )
    {
        goto ERROR_EXIT;
    } /* if */
	sleep( 1 );

	/*
     * Calculate gap size
     */

	for ( i = 0; i < MAXGAP + 3; i++ )
		uGapFrequency[i] = 0;
		
	uPreviousFrameNumber = 0;
	
    /*
     * Get and display 1000 frames of 3D data.
     */
   
    for( uFrameCnt = 0; uFrameCnt < NUM_FRAMES; ++uFrameCnt )
    {
        /*
         * Get a frame of data.
         */
		
		if( RequestNext3D() )
	    {
	       goto ERROR_EXIT;
	    } /* if */
		
		while( !DataIsReady() );
        
            /*
             * Receive the 3D data.
             */
		
            if( DataReceiveLatest3D( &uFrameNumber, &uElements, &uFlags,
                                     p3dData ) )
            {
                goto ERROR_EXIT;
            } /* if */
        
		if ( uPreviousFrameNumber != 0 )
		{
			gap = uFrameNumber - uPreviousFrameNumber;

			if ( gap < 0 )
			{
				uGapFrequency[MAXGAP + 2]++;
				fprintf( stdout, "if gap < 0\n" );
			}
			else
			{
				if ( gap > MAXGAP )
					uGapFrequency[MAXGAP + 1]++;
					
				else
					uGapFrequency[gap]++;
			}
		}
					
		uPreviousFrameNumber = uFrameNumber;

    } /* for */

	for ( i = 0; i < MAXGAP + 3; i++ )
		fprintf( stdout, "GF[%d] = %d\n", i,uGapFrequency[i]);

    fprintf( stdout, "\n" );

    /*
     * De-activate the markers.
     */
	fprintf( stdout, "...OptotrakDeActivateMarkers\n" );
    if( OptotrakDeActivateMarkers() )
    {
        goto ERROR_EXIT;
    } /* if */

    /*
     * Shutdown the processors message passing system.
     */
	fprintf( stdout, "...TransputerShutdownSystem\n" );
    if( TransputerShutdownSystem() )
    {
        goto ERROR_EXIT;
    } /* if */

    /*
     * Exit the program.
     */
    fprintf( stdout, "\nProgram execution complete.\n" );
    exit( 0 );

ERROR_EXIT:
	/*
	 * Indicate that an error has occurred
	 */
	fprintf( stdout, "\nAn error has occurred during execution of the program.\n" );
    if( OptotrakGetErrorString( szNDErrorString,
                                MAX_ERROR_STRING_LENGTH + 1 ) == 0 )
    {
        fprintf( stdout, szNDErrorString );
    } /* if */

	fprintf( stdout, "\n\n...TransputerShutdownSystem\n" );
    OptotrakDeActivateMarkers();
    TransputerShutdownSystem();

    exit( 1 );

} /* main */

