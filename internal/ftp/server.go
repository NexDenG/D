package ftp

import (
	"context"
	"net/http"
	"os"
	"path/filepath"
	"strings"

	"github.com/forscht/ddrv/internal/filesystem"
	"github.com/forscht/ddrv/pkg/ddrv"
	"github.com/rs/zerolog/log"
	"github.com/spf13/afero"
	"golang.org/x/net/webdav"
)

// Config for WebDAV server
type Config struct {
	Addr       string `mapstructure:"addr"`
	Username   string `mapstructure:"username"`
	Password   string `mapstructure:"password"`
	AsyncWrite bool   `mapstructure:"async_write"`
}

// Serv starts the WebDAV server
func Serv(drvr *ddrv.Driver, cfg *Config) error {
	if cfg.Addr == "" {
		return nil
	}

	fs := filesystem.New(drvr, cfg.AsyncWrite)

	handler := &webdav.Handler{
		FileSystem: AferoWebDAV{fs},
		LockSystem: webdav.NewMemLS(),
	}

	authHandler := basicAuth(handler, cfg.Username, cfg.Password)

	log.Info().Str("c", "webdav").Str("addr", cfg.Addr).Msg("starting webdav server")
	return http.ListenAndServe(cfg.Addr, authHandler)
}

// basicAuth middleware for HTTP Basic Authentication
func basicAuth(next http.Handler, username, password string) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		u, p, ok := r.BasicAuth()
		if !ok || u != username || p != password {
			w.Header().Set("WWW-Authenticate", `Basic realm="Restricted"`)
			http.Error(w, "Unauthorized", http.StatusUnauthorized)
			return
		}
		next.ServeHTTP(w, r)
	})
}

// AferoWebDAV adapts afero.Fs to webdav.FileSystem
type AferoWebDAV struct {
	Fs afero.Fs
}

func (a AferoWebDAV) resolvePath(name string) string {
	clean := filepath.Clean("/" + name)
	return strings.TrimPrefix(clean, "/")
}

func (a AferoWebDAV) Mkdir(ctx context.Context, name string, perm os.FileMode) error {
	return a.Fs.MkdirAll(a.resolvePath(name), perm)
}

func (a AferoWebDAV) OpenFile(ctx context.Context, name string, flag int, perm os.FileMode) (webdav.File, error) {
	f, err := a.Fs.OpenFile(a.resolvePath(name), flag, perm)
	if err != nil {
		return nil, err
	}
	return &aferoWebDAVFile{File: f}, nil
}

func (a AferoWebDAV) RemoveAll(ctx context.Context, name string) error {
	return a.Fs.RemoveAll(a.resolvePath(name))
}

func (a AferoWebDAV) Rename(ctx context.Context, oldName, newName string) error {
	return a.Fs.Rename(a.resolvePath(oldName), a.resolvePath(newName))
}

func (a AferoWebDAV) Stat(ctx context.Context, name string) (os.FileInfo, error) {
	return a.Fs.Stat(a.resolvePath(name))
}

// aferoWebDAVFile wraps afero.File for webdav compatibility
type aferoWebDAVFile struct {
	afero.File
}

func (f *aferoWebDAVFile) Seek(offset int64, whence int) (int64, error) {
	return f.File.Seek(offset, whence)
}

func (f *aferoWebDAVFile) Readdir(count int) ([]os.FileInfo, error) {
	return f.File.Readdir(count)
}

func (f *aferoWebDAVFile) Stat() (os.FileInfo, error) {
	return f.File.Stat()
}
