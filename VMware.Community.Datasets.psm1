Function New-VMDataset {
    <#
        .NOTES
        ===========================================================================
        Created by:    William Lam
        Date:          09/10/2022
        Organization:  VMware
        Blog:          http://www.williamlam.com
        Twitter:       @lamw
        ===========================================================================

        .SYNOPSIS
            Create a new vSphere Dataset
        .DESCRIPTION
            Create a new vSphere Dataset
        .PARAMETER Name
            Name of the vSphere Dataset
        .PARAMETER Description
            Description of vSphere Dataset
        .PARAMETER VMMoref
            Virtual Machine Managed Object Reference Id (e.g. vm-XX)
        .PARAMETER GuestAccess
            Whether GuestOS has (NONE, READ_ONLY or READ_WRITE) access to vSphere Dataset
        .PARAMETER HostAccess
            Whether vSphere Management has (NONE, READ_ONLY or READ_WRITE) access to vSphere Dataset
        .PARAMETER OmitFromSnapshotClone
            Whther vSphere Dataset will be part of a vSphere Snapshot / Clone
        .EXAMPLE
            $adminDataSetParam = @{
                Name = "admin-ds";
                Description = "Dataset for Admins";
                VMMoref = "vm-26";
                GuestAccess = "NONE";
                HostAccess = "READ_WRITE";
                OmitFromSnapshotClone = $false;
            }
            New-VMDataset @adminDataSetParam
        .EXAMPLE
            $sharedDataSetParam = @{
                Name = "shared-ds";
                Description = "Dataset for Admins/Users";
                VMMoref = "vm-26";
                GuestAccess = "READ_ONLY";
                HostAccess = "READ_WRITE";
                OmitFromSnapshotClone = $false;
            }
            New-VMDataset @sharedDataSetParam
        .EXAMPLE
            $userDataSetParam = @{
                Name = "user-ds";
                Description = "Dataset for Users";
                VMMoref = "vm-26";
                GuestAccess = "READ_WRITE";
                HostAccess = "READ_ONLY";
                OmitFromSnapshotClone = $false;
            }
            New-VMDataset @userDataSetParam
        .EXAMPLE
            $userDataSet2Param = @{
                Name = "private-ds";
                Description = "Dataset for Private Users";
                VMMoref = "vm-26";
                GuestAccess = "READ_WRITE";
                HostAccess = "NONE";
                OmitFromSnapshotClone = $false;
            }
            New-VMDataset @userDataSet2Param
    #>
    Param (
        [Parameter(Mandatory=$True)][String]$Name,
        [Parameter(Mandatory=$False)][String]$Description="",
        [Parameter(Mandatory=$True)][String]$VMMoRef,
        [Parameter(Mandatory=$True)][ValidateSet("NONE","READ_ONLY","READ_WRITE")][string]$GuestAccess,
        [Parameter(Mandatory=$True)][ValidateSet("NONE","READ_ONLY","READ_WRITE")][string]$HostAccess,
        [Parameter(Mandatory=$false)][Boolean]$OmitFromSnapshotClone=$false
    )

    If (-Not $global:DefaultCisServers) { Write-error "No CiS Connection found, please use Connect-CisServer`n" } Else {

        $datasets = Get-CisService -Name com.vmware.vcenter.vm.data_sets

        $spec = $datasets.Help.Create.Spec.CreateExample()
        $spec.name = $Name
        $spec.description = $Description
        $spec.guest = $GuestAccess
        $spec.host = $HostAccess
        $spec.omit_from_snapshot_and_clone = $OmitFromSnapshotClone

        Write-host -ForegroundColor Green "Creating new vSphere Dataset ${Name} for VM ${VMMoRef} ..."
        try {
            $dataset = $datasets.create($VMMoRef,$spec)
        } catch {
            Write-host -ForegroundColor red "Error in attempting to create new vSphere Dataset ${Name}"
            Write-host -ForegroundColor red "($_.Exception.Message)"
            break
        }
        Write-host -ForegroundColor green "Successfully created vSphere Dataset ..."
    }
}

Function Get-VMDataset {
    <#
        .NOTES
        ===========================================================================
        Created by:    William Lam
        Date:          09/10/2022
        Organization:  VMware
        Blog:          http://www.williamlam.com
        Twitter:       @lamw
        ===========================================================================

        .SYNOPSIS
            List or retreieve specific vSphere Dataset for a Virtual Machine
        .DESCRIPTION
            List or retreieve specific vSphere Dataset for a Virtual Machine
        .PARAMETER Name
            Name of the vSphere Dataset
        .PARAMETER VMMoRef
            Virtual Machine Managed Object Reference Id (e.g. vm-XX)
        .EXAMPLE
            Get-VMDataset -VMMoRef "vm-26"
        .EXAMPLE
            Get-VMDataset -VMMoRef "vm-26" -Name "admin-ds"
    #>
    Param (
        [Parameter(Mandatory=$False)][String]$Name,
        [Parameter(Mandatory=$True)][String]$VMMoRef
    )

    If (-Not $global:DefaultCisServers) { Write-error "No CiS Connection found, please use Connect-CisServer`n" } Else {

        $datasets = Get-CisService -Name com.vmware.vcenter.vm.data_sets

        $results = @()

        if($PSBoundParameters.ContainsKey("Name")){
            try {
                $datasets = $datasets.get($VMMoRef,$Name)

                foreach ($dataset in $datasets) {
                    $tmp = [pscustomobject] @{
                        Name = $dataset.name
                        Description = $dataset.description
                        GuestAccess = $dataset.guest
                        HostAccess = $dataset.host
                        OmitFromSnapshotClone = $dataset.omit_from_snapshot_and_clone
                        Used = $dataset.used
                    }
                    $results += $tmp
                }
            } catch {
                Write-host -ForegroundColor red "Error in attempting to retrieve specific vSphere Dataset"
                Write-host -ForegroundColor red "($_.Exception.Message)"
                break
            }
        } else {
            try {
                $datasets = $datasets.list($VMMoRef)

                foreach ($dataset in $datasets) {
                    $tmp = [pscustomobject] @{
                        Name = $dataset.name
                        Description = $dataset.description
                    }
                    $results += $tmp
                }
            } catch {
                Write-host -ForegroundColor red "Error in attempting to list vSphere Datasets"
                Write-host -ForegroundColor red "($_.Exception.Message)"
                break
            }
        }

        $results
    }
}

Function Remove-VMDataset {
    <#
        .NOTES
        ===========================================================================
        Created by:    William Lam
        Date:          09/10/2022
        Organization:  VMware
        Blog:          http://www.williamlam.com
        Twitter:       @lamw
        ===========================================================================

        .SYNOPSIS
            Remove a specific vSphere Dataset from a Virtual Machine
        .DESCRIPTION
            Remove a specific vSphere Dataset from a Virtual Machine
        .PARAMETER Name
            Name of the vSphere Dataset
        .PARAMETER VMMoRef
            Virtual Machine Managed Object Reference Id (e.g. vm-XX)
        .EXAMPLE
            Remove-VMDataset -Name "admin-ds" -VMMoRef "vm-26"
    #>
    Param (
        [Parameter(Mandatory=$True)][String]$Name,
        [Parameter(Mandatory=$True)][String]$VMMoRef
    )

    If (-Not $global:DefaultCisServers) { Write-error "No CiS Connection found, please use Connect-CisServer`n" } Else {

        $datasets = Get-CisService -Name com.vmware.vcenter.vm.data_sets

        Write-host -ForegroundColor green "Deleting vSphere Dataset ${Name} ..."
        try {
            $datasets.delete($VMMoRef,$Name)
        } catch {
            Write-host -ForegroundColor red "Error in attempting to delete vSphere Dataset ${Name}"
            Write-host -ForegroundColor red "($_.Exception.Message)"
            break
        }
        Write-host -ForegroundColor green "Successfully deleted vSphere Dataset ..."
    }
}

Function New-VMDatasetEntry {
    <#
        .NOTES
        ===========================================================================
        Created by:    William Lam
        Date:          09/10/2022
        Organization:  VMware
        Blog:          http://www.williamlam.com
        Twitter:       @lamw
        ===========================================================================

        .SYNOPSIS
            Create or update an entry in a specific vSphere Dataset for a Virtual Machine
        .DESCRIPTION
            Create or update an entry in a specific vSphere Dataset for a Virtual Machine
        .PARAMETER Name
            Name of the vSphere Dataset entry
        .PARAMETER VMMoref
            Virtual Machine Managed Object Reference Id (e.g. vm-XX)
        .PARAMETER Dataset
            Name of the vSphere Dataset
        .PARAMETER Value
            The value for vSphere Dataset entry
        .EXAMPLE
            $adminDataSetEntry1Param = @{
                Name = "Location";
                VMMoref = "vm-26";
                Dataset = "admin-ds";
                Value = "Palo Alto";
            }
            New-VMDatasetEntry @adminDataSetEntry1Param
        .EXAMPLE
            $adminDataSetEntry2Param = @{
                Name = "Building";
                VMMoref = "vm-26";
                Dataset = "admin-ds";
                Value = "Promontory E";
            }
            New-VMDatasetEntry @adminDataSetEntry2Param
        .EXAMPLE
            $sharedDataSetEntry1Param = @{
                Name = "AppID";
                VMMoref = "vm-26";
                Dataset = "shared-admin-ds";
                Value = "app-1234";
            }
            New-VMDatasetEntry @sharedDataSetEntry1Param
        .EXAMPLE
            $sharedDataSetEntry2Param = @{
                Name = "SystemOwner";
                VMMoref = "vm-26";
                Dataset = "shared-admin-ds";
                Value = "William Lam";
            }
            New-VMDatasetEntry @sharedDataSetEntry2Param
    #>
    Param (
        [Parameter(Mandatory=$True)][String]$VMMoRef,
        [Parameter(Mandatory=$True)][String]$Dataset,
        [Parameter(Mandatory=$True)][String]$Name,
        [Parameter(Mandatory=$True)][String]$Value
    )

    If (-Not $global:DefaultCisServers) { Write-error "No CiS Connection found, please use Connect-CisServer`n" } Else {

        $datasetEntries = Get-CisService -Name com.vmware.vcenter.vm.data_sets.entries

        $datasetEntries.set($VMMoRef, $Dataset, $Name, $value)

        Write-host -ForegroundColor Green "Creating new vSphere Dataset Entry ${Name} for VM ${VMMoRef} ..."
        try {
            $datasetEntry = $datasetEntries.set($VMMoRef, $Dataset, $Name, $value)
        } catch {
            Write-host -ForegroundColor red "Error in attempting to create new vSphere Dataset Entry ${Name}"
            Write-host -ForegroundColor red "($_.Exception.Message)"
            break
        }
        Write-host -ForegroundColor green "Successfully created vSphere Dataset Entry ..."
    }
}

Function Get-VMDatasetEntry {
    <#
        .NOTES
        ===========================================================================
        Created by:    William Lam
        Date:          09/10/2022
        Organization:  VMware
        Blog:          http://www.williamlam.com
        Twitter:       @lamw
        ===========================================================================

        .SYNOPSIS
            List or retreieve specific entry within a vSphere Dataset for a Virtual Machine
        .DESCRIPTION
            List or retreieve specific entry within a vSphere Dataset for a Virtual Machine
        .PARAMETER Name
            Name of the vSphere Dataset entry
        .PARAMETER VMMoRef
            Virtual Machine Managed Object Reference Id (e.g. vm-XX)
        .PARAMETER Dataset
            Name of the vSphere Dataset
        .EXAMPLE
            Get-VMDatasetEntry -VMMoRef "vm-26" -Dataset "admin-ds"
        .EXAMPLE
            Get-VMDatasetEntry -VMMoRef "vm-26" -Dataset "admin-ds" -Name "Test"
    #>
    Param (
        [Parameter(Mandatory=$False)][String]$Name,
        [Parameter(Mandatory=$True)][String]$VMMoRef,
        [Parameter(Mandatory=$True)][String]$Dataset
    )

    If (-Not $global:DefaultCisServers) { Write-error "No CiS Connection found, please use Connect-CisServer`n" } Else {

        $datasetEntries = Get-CisService -Name com.vmware.vcenter.vm.data_sets.entries

        $results = @()

        if($PSBoundParameters.ContainsKey("Name")){
            try {
                $dsEntries = $datasetEntries.get($VMMoRef,$Dataset,$Name)

                $results = $dsEntries
            } catch {
                Write-host -ForegroundColor red "Error in attempting to retrieve a specific vSphere Dataset Entry"
                Write-host -ForegroundColor red "($_.Exception.Message)"
                break
            }
        } else {
            try {
                $dsEntries = $datasetEntries.list($VMMoRef,$Dataset)

                $results = $dsEntries
            } catch {
                Write-host -ForegroundColor red "Error in attempting to list vSphere Dataset Entries"
                Write-host -ForegroundColor red "($_.Exception.Message)"
                break
            }
        }

        $results
    }
}

Function Remove-VMDatasetEntry {
    <#
        .NOTES
        ===========================================================================
        Created by:    William Lam
        Date:          09/10/2022
        Organization:  VMware
        Blog:          http://www.williamlam.com
        Twitter:       @lamw
        ===========================================================================

        .SYNOPSIS
            Remove vSphere Dataset Entry from a Virtual Machine
        .DESCRIPTION
            Remove vSphere Dataset Entry from a Virtual Machine
        .PARAMETER Name
            Name ofthe vSphere Dataset entry
        .PARAMETER VMMoRef
            Virtual Machine Managed Object Reference Id (e.g. vm-XX)
        .PARAMETER Dataset
            Name of the vSphere Dataset
        .EXAMPLE
            Remove-VMDataset -Name "Location" -VMMoRef "vm-26" -Dataset "admin-ds"
    #>
    Param (
        [Parameter(Mandatory=$True)][String]$Name,
        [Parameter(Mandatory=$True)][String]$VMMoRef,
        [Parameter(Mandatory=$True)][String]$Dataset
    )

    If (-Not $global:DefaultCisServers) { Write-error "No CiS Connection found, please use Connect-CisServer`n" } Else {

        $datasetEntries = Get-CisService -Name com.vmware.vcenter.vm.data_sets.entries

        Write-host -ForegroundColor green "Deleting vSphere Dataset Entry ${Name} for Dataset ${Dataset} ..."
        try {
            $datasetEntries.delete($VMMoRef,$Dataset,$Name)
        } catch {
            Write-host -ForegroundColor red "Error in attempting to delete vSphere Dataset Entry ${Name}"
            Write-host -ForegroundColor red "($_.Exception.Message)"
            break
        }
        Write-host -ForegroundColor green "Successfully deleted vSphere Dataset Entry ..."
    }
}