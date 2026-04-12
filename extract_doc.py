import zipfile
import xml.etree.ElementTree as ET
import sys
import os

# Find the document
folder = r"C:\Users\eslim\ANDA QUE ANDA"
files = [f for f in os.listdir(folder) if f.endswith('.docx') and 'libreria' in f.lower()]

if not files:
    print("Document not found")
    sys.exit(1)

docx_path = os.path.join(folder, files[0])
print(f"Found: {files[0]}")

# Open docx (it's a zip)
with zipfile.ZipFile(docx_path, 'r') as zip_ref:
    # Get document.xml
    doc_xml = zip_ref.read('word/document.xml').decode('utf-8')
    
    # Get relationships
    rels_xml = zip_ref.read('word/_rels/document.xml.rels').decode('utf-8')
    
    # Parse relationships to map image IDs to filenames
    rels_root = ET.fromstring(rels_xml)
    image_map = {}
    for rel in rels_root.findall('.//{http://schemas.openxmlformats.org/package/2006/relationships}Relationship'):
        if 'image' in rel.get('Type', ''):
            r_id = rel.get('Id')
            target = rel.get('Target')
            filename = os.path.basename(target)
            image_map[r_id] = filename
    
    # Parse document.xml
    root = ET.fromstring(doc_xml)
    
    # Namespaces
    ns = {
        'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main',
        'r': 'http://schemas.openxmlformats.org/officeDocument/2006/relationships',
        'a': 'http://schemas.openxmlformats.org/drawingml/2006/main',
        'pic': 'http://schemas.openxmlformats.org/drawingml/2006/picture',
        'wp': 'http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing'
    }
    
    content = []
    body = root.find('.//w:body', ns)
    
    # Process all child nodes in order
    for elem in body:
        if elem.tag.endswith('}p'):  # paragraph
            para = elem
            
            # Find images first
            for blip in para.findall('.//a:blip', ns):
                embed = blip.find('r:embed', ns)
                if embed is not None:
                    r_id = embed.get('{http://schemas.openxmlformats.org/officeDocument/2006/relationships}embed')
                    if r_id in image_map:
                        content.append(('IMAGE', image_map[r_id]))
            
            # Find inline drawings
            for inline in para.findall('.//wp:inline', ns):
                blip = inline.find('.//a:blip', ns)
                if blip is not None:
                    embed = blip.find('r:embed', ns)
                    if embed is not None:
                        r_id = embed.get('{http://schemas.openxmlformats.org/officeDocument/2006/relationships}embed')
                        if r_id in image_map:
                            content.append(('IMAGE', image_map[r_id]))
            
            # Get text
            text_parts = []
            for t in para.findall('.//w:t', ns):
                if t.text:
                    text_parts.append(t.text)
            
            text = ''.join(text_parts).strip()
            if text:
                content.append(('TEXT', text))
    
    # Write output
    with open('libreria_EXACT_order.txt', 'w', encoding='utf-8') as f:
        for i, (item_type, value) in enumerate(content, 1):
            f.write(f"[{i}] {item_type}: {value}\n\n")
    
    print(f"Extracted {len(content)} items")
    print(f"Images: {sum(1 for t, v in content if t == 'IMAGE')}")
    print(f"Text blocks: {sum(1 for t, v in content if t == 'TEXT')}")
