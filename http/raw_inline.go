package http

import (
	//"log"
	"net/http"
	"github.com/filebrowser/filebrowser/v2/files"
)

var rawInlineHandler = withUser(func(w http.ResponseWriter, r *http.Request, d *data) (int, error) {

	if !d.user.Perm.Download {
		return http.StatusAccepted, nil
	}

	file, err := files.NewFileInfo(&files.FileOptions{
		Fs:         d.user.Fs,
		Path:       r.URL.Path,
		Modify:     d.user.Perm.Modify,
		Expand:     false,
		ReadHeader: d.server.TypeDetectionByHeader,
		Checker:    d,
	})

	if err != nil {
		return errToStatus(err), err
	}

	//log.Printf("...")

	if !file.IsDir {
		return rawInlineFileHandler(w, r, file)
	}

	return http.StatusAccepted, nil
})

func rawInlineFileHandler(w http.ResponseWriter, r *http.Request, file *files.FileInfo) (int, error) {

	fd, err := file.Fs.Open(file.Path)
	if err != nil {
		return http.StatusInternalServerError, err
	}
	defer fd.Close()

	w.Header().Set("Content-Disposition", "inline") //inline

	w.Header().Add("Content-Security-Policy", `script-src 'none';`)
	w.Header().Set("Cache-Control", "private")
	http.ServeContent(w, r, file.Name, file.ModTime, fd)
	return 0, nil
}

