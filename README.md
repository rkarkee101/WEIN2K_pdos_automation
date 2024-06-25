# WEIN2K_pdos_automation

This is a simple bash script that automates the WEIN2K for pdos calculation.

All you need is a cif file.


The working steps are as follows:

1) Name the working directory as name of cif file
2) Put .cif file and automate.sh, job_automate and job into that directory
3) sbatch job_automate

If one needs to change parameters, for example vxc or k-mesh size, that can be done by editing job_automate.sh
The status of calculation is shown in automate.log
