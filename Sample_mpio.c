#include <mpi.h>
#ifndef MPI_FILE_NULL           /*MPIO may be defined in mpi.h already       */
#   include <mpio.h>
#endif

#define DIMSIZE	10		/* dimension size, avoid powers of 2. */
#define PRINTID printf("Proc %d: ", mpi_rank)

main(int ac, char **av)
{
    char hostname[128];
    int  mpi_size, mpi_rank;
    MPI_File fh;
    char *filename = "./mpitest.data";
    char mpi_err_str[MPI_MAX_ERROR_STRING];
    int  mpi_err_strlen;
    int  mpi_err;
    char writedata[DIMSIZE], readdata[DIMSIZE];
    char expect_val;
    int  i, irank; 
    int  nerrors = 0;		/* number of errors */
    MPI_Offset  mpi_off;
    MPI_Status  mpi_stat;

    MPI_Init(&ac, &av);
    MPI_Comm_size(MPI_COMM_WORLD, &mpi_size);
    MPI_Comm_rank(MPI_COMM_WORLD, &mpi_rank);

    /* get file name if provided */
    if (ac > 1){
	filename = *++av;
    }
    if (mpi_rank==0){
	printf("Testing simple MPIO program with %d processes accessing file %s\n",
	    mpi_size, filename);
        printf("    (Filename can be specified via program argument)\n");
    }

    /* show the hostname so that we can tell where the processes are running */
    if (gethostname(hostname, 128) < 0){
	PRINTID;
	printf("gethostname failed\n");
	return 1;
    }
    PRINTID;
    printf("hostname=%s\n", hostname);

    if ((mpi_err = MPI_File_open(MPI_COMM_WORLD, filename,
	    MPI_MODE_RDWR | MPI_MODE_CREATE | MPI_MODE_DELETE_ON_CLOSE,
	    MPI_INFO_NULL, &fh))
	    != MPI_SUCCESS){
	MPI_Error_string(mpi_err, mpi_err_str, &mpi_err_strlen);
	PRINTID;
	printf("MPI_File_open failed (%s)\n", mpi_err_str);
	return 1;
    }

    /* each process writes some data */
    for (i=0; i < DIMSIZE; i++)
	writedata[i] = mpi_rank*DIMSIZE + i;
    mpi_off = mpi_rank*DIMSIZE;
    if ((mpi_err = MPI_File_write_at(fh, mpi_off, writedata, DIMSIZE, MPI_BYTE,
	    &mpi_stat))
	    != MPI_SUCCESS){
	MPI_Error_string(mpi_err, mpi_err_str, &mpi_err_strlen);
	PRINTID;
	printf("MPI_File_write_at offset(%ld), bytes (%d), failed (%s)\n",
		(long) mpi_off, (int) DIMSIZE, mpi_err_str);
	return 1;
    };

    /* make sure all processes has done writing. */
    MPI_Barrier(MPI_COMM_WORLD);

    /* each process reads all data and verify. */
    for (irank=0; irank < mpi_size; irank++){
	mpi_off = irank*DIMSIZE;
	if ((mpi_err = MPI_File_read_at(fh, mpi_off, readdata, DIMSIZE, MPI_BYTE,
		&mpi_stat))
		!= MPI_SUCCESS){
	    MPI_Error_string(mpi_err, mpi_err_str, &mpi_err_strlen);
	    PRINTID;
	    printf("MPI_File_read_at offset(%ld), bytes (%d), failed (%s)\n",
		    (long) mpi_off, (int) DIMSIZE, mpi_err_str);
	    return 1;
	};
	for (i=0; i < DIMSIZE; i++){
	    expect_val = irank*DIMSIZE + i;
	    if (readdata[i] != expect_val){
		PRINTID;
		printf("read data[%d:%d] got %d, expect %d\n", irank, i,
			readdata[i], expect_val);
		nerrors++;
	    }
	}
    }
    if (nerrors)
	return 1;

    MPI_File_close(&fh);

    PRINTID;
    printf("all tests passed\n");

    MPI_Finalize();
    return 0;
}

