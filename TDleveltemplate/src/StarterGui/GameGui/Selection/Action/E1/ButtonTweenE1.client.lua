local btn = script.Parent

btn.MouseEnter:Connect(function() 
	btn:TweenSize(UDim2.new(0.65,0,.2,0), Enum.EasingDirection.InOut,Enum.EasingStyle.Quad, .2,true) 
end) 

btn.MouseLeave:Connect(function() 
	btn:TweenSize(UDim2.new(0.55,0,.2,0), Enum.EasingDirection.InOut,Enum.EasingStyle.Quad, .2,true) 
end)
