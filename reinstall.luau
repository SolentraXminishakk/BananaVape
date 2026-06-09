local cloneref = cloneref or function(ref: any)
    return ref
end

if isfolder('bananavxpe') then
    delfolder('bananavxpe')
end

cloneref(game:GetService('StarterGui')):SetCore('SendNotification', {
    Title = 'Banana Vape',
    Text = 'Successfully reinstalled Banana Vape, Please rejoin the game to take effect',
    Duration = 20
})
