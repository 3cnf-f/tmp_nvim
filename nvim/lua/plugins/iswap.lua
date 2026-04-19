return {                                                                                                                                           
  "mizlan/iswap.nvim",                                                                                                                             
  event = "VeryLazy",                                                                                                                              
  opts = {                                                                                                                                         
    -- Highlight colors (using your Kanagawa/Everforest theme logic implicitly)                                                                    
    hl_snipe = "ErrorMsg",  -- The item you are currently holding                                                                                  
    hl_selection = "Visual", -- The item you want to swap with                                                                                     
    flash_style = "simultaneous",                                                                                                                  
  },                                                                                                                                               
  keys = {                                                                                                                                         
    -- 'cx' to pick an item, then pick a destination to swap                                                                                       
    { "cx", "<cmd>ISwap<CR>", desc = "Swap Arguments/Items" },                                                                                     
    -- 'cX' to swap the item under cursor with a specific target immediately                                                                       
    { "cX", "<cmd>ISwapWith<CR>", desc = "Swap Current With..." },                                                                                 
  },                                                                                                                                               
}                                                         
