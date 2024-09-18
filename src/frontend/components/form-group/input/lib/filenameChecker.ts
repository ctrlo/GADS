export function needsRename(filename:string) {
    const pattern = /[^a-zA-Z0-9]/g;
    const parts = filename.split('.');
    return parts.length>2 || parts[0].match(pattern);
}

export function checkFilename(filename: string) {
    const pattern = /[^a-zA-Z0-9]/g;
    const parts = filename.split('.');
    const max = parts.length - 1;
    if(max === 0 || parts.length == 1) throw new Error('Invalid file name - no extension found');
    if (parts[max].length == 0) throw new Error('Invalid file name - no extension found');
    if (parts[max].match(pattern)) throw new Error('Invalid file name - invalid characters in extension');
    let result = '';
    for(let i = 0; i < max; i++)
        result = result + parts[i].replace(pattern, '');
    if(result.length == 0) throw new Error('Invalid file name - no file name found');
    return result + '.' + parts[max];
}
