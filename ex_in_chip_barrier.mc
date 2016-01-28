#include <libmap.h>

void subr (int64_t In[], int64_t Out[], int Line_Length, int Num_Lines, int64_t *tm, int mapnum) {

    OBM_BANK_A (AL, int64_t, MAX_OBM_SIZE)
    OBM_BANK_B (BL, int64_t, MAX_OBM_SIZE)
    OBM_BANK_C (CL, int64_t, MAX_OBM_SIZE)

    Stream_64 SIn, SOut;
    int  nval;
    int64_t t0,t1;
    In_Chip_Barrier Bar0,Bar1;

    nval = Num_Lines * Line_Length;

    In_Chip_Barrier_Set (&Bar0,3);
    In_Chip_Barrier_Set (&Bar1,3);

    read_timer (&t0);

    #pragma src parallel sections
    {
        #pragma src section
        {
         int i,indx;
         indx = 0;
         for (i=0;i<Num_Lines;i++)  {
           streamed_dma_cpu_64 (&SIn, PORT_TO_STREAM, &In[indx], Line_Length*8);
           indx = indx + Line_Length;

           In_Chip_Barrier_Wait (&Bar0);
           In_Chip_Barrier_Wait (&Bar1);
        }
        }
        #pragma src section
        {
           int i,j;
           int64_t v0;

         for (i=0;i<Num_Lines;i++)  {
           for (j=0; j<Line_Length; j++) {
               get_stream_64 (&SIn, &v0);

               if (i&1) BL[j] = v0;
               else     AL[j] = v0;
           }
           In_Chip_Barrier_Wait (&Bar0);
           In_Chip_Barrier_Wait (&Bar1);
        }
        }
        #pragma src section
        {
        int64_t v0;
        int i,j,ix,n_sample,n_line;

           for (i=0;i<Num_Lines;i++)  {
              In_Chip_Barrier_Wait (&Bar0);

               for (j=0; j<Line_Length; j++) {
                   ix = Line_Length - j -1;

                   if (i&1) v0 = BL[ix];
                   else     v0 = AL[ix];


                   put_stream_64 (&SOut, v0, 1);
               }
 printf ("    b4 barrier1\n");
              In_Chip_Barrier_Wait (&Bar1);
 printf ("    af barrier1\n");
           }
        }
        #pragma src section
        {
        streamed_dma_cpu_64 (&SOut, STREAM_TO_PORT, Out, nval*8);
        }
    }

    read_timer (&t1);
    *tm = t1 - t0;
}
