function mff = calcff(mf, nm, pkg)
if pkg == 7
    mff = mf ./ (nm + 2);
elseif pkg == 12
    mff = mf ./ (nm + 1.3);
else
    error('invalid pkg')
end