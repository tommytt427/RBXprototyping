local btn = script.Parent

btn.MouseEnter:Connect(function() 
	btn:TweenSize(UDim2.new(0,100,0,168), Enum.EasingDirection.InOut,Enum.EasingStyle.Quad, .2,true) 
end) 

btn.MouseLeave:Connect(function() 
	btn:TweenSize(UDim2.new(0,100,0,148), Enum.EasingDirection.InOut,Enum.EasingStyle.Quad, .2,true) 
end)
