Updates for the SR-6.4.0 release given an untarred copy of
BBS_6.4.0/skxp_mcp_640_gbs_dev_pkg_ww38.tar.gz.

The transformed build environment is compatible only with OPAE, since the platform interface
manager is integrated into the OPAE SDK. The blue/green boundary remains unchanged and builds
are compatible with the standard SR-6.4.0 FIU.

HSSI has not been tested.  The interface to HSSI is transformed to be similar to the
discrete platform, but the Platform Interface Manager definitions required to request
an HSSI connection are not yet defined.
