function Invoke-ListCommunityRepos {
    <#
    .SYNOPSIS
        List community repositories in Table Storage
    .DESCRIPTION
        This function lists community repositories in Table Storage
    .FUNCTIONALITY
        Entrypoint
    .ROLE
        CIPP.Core.Read
    #>
    [CmdletBinding()]
    param($Request, $TriggerMetadata)

    $Table = Get-CIPPTable -TableName CommunityRepos
    $Repos = Get-CIPPAzDataTableEntity @Table

    $CIPPRoot = (Get-Item (Get-Module -Name CIPPCore).ModuleBase).Parent.Parent.FullName
    $CommunityRepos = Join-Path -Path $CIPPRoot -ChildPath 'CommunityRepos.json'
    $DefaultCommunityRepos = Get-Content -Path $CommunityRepos -Raw | ConvertFrom-Json

    $DefaultsMissing = $false
    foreach ($Repo in $DefaultCommunityRepos) {
        if ($Repos.Url -notcontains $Repo.Url) {
            $Entity = [PSCustomObject]@{
                PartitionKey = 'CommunityRepos'
                RowKey       = $Repo.Id
                Name         = $Repo.Name
                Description  = $Repo.Description
                URL          = $Repo.URL
                FullName     = $Repo.FullName
                Owner        = $Repo.Owner
                Visibility   = $Repo.Visibility
                WriteAccess  = $Repo.WriteAccess
                Permissions  = [string]($Repo.RepoPermissions | ConvertTo-Json)
            }
            Add-CIPPAzDataTableEntity @Table -Entity $Entity
            $DefaultsMissing = $true
        }
    }
    if ($DefaultsMissing) {
        $Repos = Get-CIPPAzDataTableEntity @Table
    }

    $Repos = $Repos | ForEach-Object {
        [pscustomobject]@{
            Id              = $_.RowKey
            Name            = $_.Name
            Description     = $_.Description
            URL             = $_.URL
            FullName        = $_.FullName
            Owner           = $_.Owner
            Visibility      = $_.Visibility
            WriteAccess     = $_.WriteAccess
            RepoPermissions = $_.Permissions | ConvertFrom-Json
        }
    }

    $Body = @{
        Results = @($Repos | Sort-Object -Property FullName)
    }

    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK
            Body       = $Body
        })
}
