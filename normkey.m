function nm = normkey(s)
    % 标准键：小写 + 去掉所有非字母数字（下划线/空格/破折号等统统去掉）
    nm = lower(regexprep(s, '[^a-zA-Z0-9]', ''));
end