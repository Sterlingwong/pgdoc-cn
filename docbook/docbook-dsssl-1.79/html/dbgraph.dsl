;; $Id: dbgraph.dsl,v 1.6 2003/03/25 19:53:40 adicarlo Exp $
;;
;; This file is part of the Modular DocBook Stylesheet distribution.
;; See ../README or http://docbook.sourceforge.net/projects/dsssl/
;;

;; ==================== GRAPHICS ====================

(define (graphic-file filename)
  (let ((ext (file-extension filename)))
    (if (or (not filename)
	    (not %graphic-default-extension%)
	    (member ext %graphic-extensions%))
	filename
	(string-append filename "." %graphic-default-extension%))))

(define (graphic-attrs imagefile instance-alt)
  (let* ((grove    (sgml-parse image-library-filename))
	 (imagelib (node-property 'document-element 
				  (node-property 'grove-root grove)))
	 (images   (select-elements (children imagelib) "image"))
	 (image    (let loop ((imglist images))
		     (if (node-list-empty? imglist)
			 #f
			 (if (equal? (attribute-string 
				      "filename"
				      (node-list-first imglist))
				     imagefile)
			     (node-list-first imglist)
			     (loop (node-list-rest imglist))))))
	 (prop     (if image
		       (select-elements (children image) "properties")
		       #f))
	 (metas    (if prop
		       (select-elements (children prop) "meta")
		       #f))
	 (attrs    (if metas
		       (let loop ((meta metas) (attrlist '()))
			 (if (node-list-empty? meta)
			     attrlist
			     (if (equal? (attribute-string 
					  "imgattr"
					  (node-list-first meta))
					 "yes")
				 (loop (node-list-rest meta)
				       (append attrlist
					       (list 
						(list 
						 (attribute-string 
						  "name"
						  (node-list-first meta))
						 (attribute-string
						  "content"
						  (node-list-first meta))))))
				 (loop (node-list-rest meta) attrlist))))
		       '()))
	 (width    (if prop (attribute-string "width" prop) #f))
	 (height   (if prop (attribute-string "height" prop) #f))
	 (alttext  (if image
		       (select-elements (children image) "alttext")
		       (empty-node-list)))
	 (alt      (if instance-alt
		       instance-alt
		       (if (node-list-empty? alttext)
			   #f
			   (data alttext)))))
    (if (or width height alt (not (null? attrs)))
	(append
	 attrs
	 (if width   (list (list "WIDTH" width)) '())
	 (if height  (list (list "HEIGHT" height)) '())
	 (if (not (node-list-empty? alttext)) (list (list "ALT" alt)) '()))
	'())))

(define ($graphic$ fileref
		   #!optional (format #f) (alt #f) (align #f) (width #f) (height #f))
  (let ((img-attr  (append
		    (list     (list "SRC" (graphic-file fileref)))
		    (if align (list (list "ALIGN" align)) '())
		    (if width (list (list "WIDTH" width)) '())
		    (if height (list (list "HEIGHT" height)) '())
		    (if image-library (graphic-attrs fileref alt) '()))))
    (make empty-element gi: "IMG"
	  attributes: img-attr)))

(define ($img$ #!optional (nd (current-node)) (alt #f))
  ;; This function now supports an extension to DocBook.  It's
  ;; either a clever trick or an ugly hack, depending on your
  ;; point of view, but it'll hold us until XLink is finalized
  ;; and we can extend DocBook the "right" way.
  ;;
  ;; If the entity passed to GRAPHIC has the FORMAT
  ;; "LINESPECIFIC", either because that's what's specified or
  ;; because it's the notation of the supplied ENTITYREF, then
  ;; the text of the entity is inserted literally (via Jade's
  ;; read-entity external procedure).
  ;;
  (let* ((fileref   (attribute-string (normalize "fileref") nd))
	 (entityref (attribute-string (normalize "entityref") nd))
	 (format    (if (attribute-string (normalize "format") nd)
			(attribute-string (normalize "format") nd)
			(if entityref
			    (entity-notation entityref)
			    #f)))
	 (align     (attribute-string (normalize "align") nd))
	 (width     (attribute-string (normalize "width") nd))
	 (height    (attribute-string (normalize "depth") nd)))
    (if (or fileref entityref)
	(if (equal? format (normalize "linespecific"))
	    (if fileref
		(include-file fileref)
		(include-file (entity-generated-system-id entityref)))
	    (if fileref
		($graphic$ fileref format alt align width height)
		($graphic$ (system-id-filename entityref)
			   format alt align width height)))
	(empty-sosofo))))

(element graphic
  (make element gi: "P"
	($img$)))

(element inlinegraphic
  ($img$))

;; ======================================================================
;; MediaObject and friends...

(define preferred-mediaobject-notations
  (list "JPG" "JPEG" "PNG" "linespecific"))

(define preferred-mediaobject-extensions
  (list "jpeg" "jpg" "png" "avi" "mpg" "mpeg" "qt"))

(define acceptable-mediaobject-notations
  (list "GIF" "GIF87a" "GIF89a" "BMP" "WMF"))

(define acceptable-mediaobject-extensions
  (list "gif" "bmp" "wmf"))

(element mediaobject
  (make element gi: "DIV"
	attributes: (list (list "CLASS" (gi)))
	(make element gi: "P"
	      ($mediaobject$))))

(element inlinemediaobject
  (make element gi: "SPAN"
	attributes: (list (list "CLASS" (gi)))
	($mediaobject$)))

(element mediaobjectco
  (process-children))

(element imageobjectco
  (process-children))

(element objectinfo
  (empty-sosofo))

(element videoobject
  (process-children))

(element videodata
  (let ((filename (data-filename (current-node))))
    (make element gi: "EMBED"
	  attributes: (list (list "SRC" filename)))))

(element audioobject
  (process-children))

(element audiodata
  (let ((filename (data-filename (current-node))))
    (make element gi: "EMBED"
	  attributes: (list (list "SRC" filename)))))

(element imageobject
  (process-children))

(element imagedata
  (let* ((filename (data-filename (current-node)))
	 (mediaobj (parent (parent (current-node))))
	 (textobjs (select-elements (children mediaobj) 
				    (normalize "textobject")))
	 (alttext  (let loop ((nl textobjs) (alttext #f))
		     (if (or alttext (node-list-empty? nl))
			 alttext
			 (let ((phrase (select-elements 
					(children 
					 (node-list-first nl))
					(normalize "phrase"))))
			   (if (node-list-empty? phrase)
			       (loop (node-list-rest nl) #f)
			       (loop (node-list-rest nl)
				     (data (node-list-first phrase))))))))
	 (fileref   (attribute-string (normalize "fileref")))
	 (entityref (attribute-string (normalize "entityref")))
	 (format    (if (attribute-string (normalize "format"))
			(attribute-string (normalize "format"))
			(if entityref
			    (entity-notation entityref)
			    #f))))
    (if (equal? format (normalize "linespecific"))
	(if fileref
	    (include-file fileref)
	    (include-file (entity-generated-system-id entityref)))
	($img$ (current-node) alttext))))

(element textobject
  (make element gi: "DIV"
	attributes: (list (list "CLASS" (gi)))
	(process-children)))

(element caption
  (make element gi: "DIV"
	attributes: (list (list "CLASS" (gi)))
	(process-children)))

