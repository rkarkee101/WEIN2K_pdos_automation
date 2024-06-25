#!/bin/bash

num_kpoints=10000  #Change K-points mesh for dos calculation after scf
shift_option=0     # 0 for no shift in k-mesh, 1 for shifted grid
ECUT=-10   #Change Ecut as per need
FUNCTIONAL=PBE   #Change XC as per need 

current_dir=$(basename "$PWD")


cif_file="${current_dir}.cif"

cif2struct $cif_file
x sgroup
cp ${current_dir}.struct_sgroup ${current_dir}.struct


init_lapw -b -vxc $FUNCTIONAL -numk 1000 -ecut $ECUT


echo "init_lapw Initialization completed!!"


#Submit job
echo "################################################"
echo "Submitting job.. for scf calculation"

sbatch job


echo "Waiting for job to complete..."

while true; do
        if tail -n 1 stdoutput.out | grep '>   stop';then
                echo "Scf calculation completed."
                break
        else
                echo "Job is still in queue or running. Check again in 60 seconds..."
                sleep 60
        fi
done

echo "**********************************************"

echo "Generating denser grid.."

echo " ###############################################"

x kgen <<EOF
$num_kpoints
$shift_option
EOF

echo "Denser k-mesh generation completed."
echo "***********************************"

echo "Eigenvalues with denser k-mesh"
x lapw1

echo "Partial density"
echo "#################################################"

x lapw2 -qtl
echo "lapw2 -qtl completed"
echo "***********************************************"

echo "Reading .qtl file for finding orbitals of the atoms"
echo "##################################################"

qtl_file="${current_dir}.qtl"

# Check if the .qtl file exists
if [ ! -f "$qtl_file" ]; then
    echo "Error: File '$qtl_file' not found!"
    exit 1
fi

# Read the JATOM lines and process them
jatom_lines=$(grep 'JATOM' "$qtl_file")
output=""

while IFS= read -r line; do
    # Extract the JATOM number and the elements after ISPLIT
    jatom_number=$(echo "$line" | awk '{print $2}')
    elements=$(echo "$line" | awk '{print $NF}')

    # Replace 0 with s, 1 with p, 2 with d, 3 with f
    modified_elements=$(echo "$elements" | sed -E 's/\<0\>/s/g; s/\<1\>/p/g; s/\<2\>/d/g; s/\<3\>/f/g')

    # Append to the output string
    output+=" ${jatom_number} ${modified_elements}"
done <<< "$jatom_lines"

# Construct the configure_init_lapw command
configure_command="configure_init_lapw -b total ${output} end"

# Print the constructed command
echo "$configure_command"

echo "Executing the configure_init_lapw command"
echo "#############################################################################"

/usr/projects/cint/cint_codes/wien2k/2k.19.1-ch/configure_int_lapw -b total ${output} end

echo "configure_init_lapw completed"
echo "*************************************************************************"

echo "Executing dos calculation"
echo "#####################################################################"
x tetra

echo "DOS/PDOS calculation is now complete!"
echo "*************************************"
