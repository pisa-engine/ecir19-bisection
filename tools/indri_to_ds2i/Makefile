
# CONFIG REQUIRED: SET THIS VARIABLE TO THE PATH OF THE INDRI SOURCE CODE
INDRISRC=../../external/indri
include $(INDRISRC)/MakeDefns
SHARED=
INCPATH=-I$(INDRISRC) -I$(INDRISRC)/include $(patsubst %, -I$(INDRISRC)/contrib/%/include, $(DEPENDENCIES)) -I..
LIBPATH=-L$(INDRISRC)/obj $(patsubst %, -L$(INDRISRC)/contrib/%/obj, $(DEPENDENCIES))
LIBS=-lindri $(patsubst %, -l%, $(DEPENDENCIES))

all: indri


indri:
	$(CXX) $(CXXFLAGS) -Wno-write-strings -O3 -msse4.2 -std=c++11 indri_to_ds2i.cpp -o indri_to_ds2i $(INCPATH) $(LIBPATH) $(LIBS) $(CPPLDFLAGS)

clean:
	rm -f indri_to_ds2i

