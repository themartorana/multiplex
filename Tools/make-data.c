#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <ctype.h>

int
main (int argc, char* argv[])
{
    FILE* ifp,* ofp;
    unsigned int pos;
    int ch, i;
    
    if (argc != 4) {
        fprintf (stderr, "Usage: %s DATANAME INPUT OUTPUT\n", argv[0]);
        exit (1);
    }
    
    if (0 == strcmp(argv[2], "-")) {
        ifp = stdin;
    } else {
        ifp = fopen (argv[2], "r");
        if (ifp == NULL) {
            fprintf (stderr, "%s: couldn't open input file \"%s\": %s\n",
                     argv[0], argv[2], strerror (errno));
            exit (1);
        }
    }
    
    ofp = fopen (argv[3], "w");
    if (ofp == NULL) {
        fprintf (stderr, "%s: couldn't create output file \"%s\": %s\n",
                 argv[0], argv[3], strerror (errno));
        exit (1);
    }
    
    fprintf (ofp, "static uint8_t %s[] = \\\n  \"", argv[1]);
    
    pos = 0;
    
    while ((ch = getc (ifp)) != EOF) {
        if ((pos % 16) == 0 && pos) {
            fprintf (ofp, "\" \\\n  \"");
        }
        fprintf (ofp, "\\x%02x", ch);
        pos++;
    }
    
    fprintf (ofp, "\";\n");
//    fprintf (ofp, "static uint32_t %s_len = %u;\n", argv[1], pos);
    
    for (i = 0; argv[1][i]; i++)
        if (islower (argv[1][i])) {
            argv[1][i] = toupper (argv[1][i]);
        }
    
    fprintf (ofp, "#define %s_LEN %u\n", argv[1], pos);
    
    fclose (ifp);
    fclose (ofp);
    
    return 0;
}
