package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"go/ast"
	"go/constant"
	"go/importer"
	"go/parser"
	"go/token"
	"go/types"
	"io"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
)

type pkgInfo struct {
	ImportPath string
	Dir        string
	GoFiles    []string
	Export     string
	Module     *struct{ Path string }
}

type route struct {
	Svc, Method, Path, Where, Handler string
	Roles                             []string
}

type key struct {
	file string
	line int
}

var (
	fset    = token.NewFileSet()
	exports = map[string]string{}
	decls   = map[key]*ast.FuncDecl{}
	infos   = map[string]*types.Info{}
	files   = map[string]*ast.File{}
	fileInf = map[string]*types.Info{}
	methods = map[string][]*types.Func{}
	modPath = "github.com/siteeksen/backend"
	sqlW    = regexp.MustCompile(`(?i)\b(INSERT\s+INTO|UPDATE|DELETE\s+FROM)\s+([a-z_][a-z0-9_]+)`)
	sqlR    = regexp.MustCompile(`(?i)\b(?:FROM|JOIN)\s+([a-z_][a-z0-9_]{2,})`)
	sqlF    = regexp.MustCompile(`\b(resident_can_use|assessment_visible_to|unit_occupancy)\b`)
	skipR   = map[string]bool{"jsonb_array_elements": true, "unnest": true, "generate_series": true, "lateral": true, "last": true, "first": true, "the": true, "jsonb_each": true, "json_each": true, "regexp_split_to_table": true, "string_to_table": true, "jsonb_to_recordset": true, "jsonb_array_elements_text": true, "pg_class": true, "pg_namespace": true, "pg_policies": true, "now": true}
)

func main() {
	dec := json.NewDecoder(os.Stdin)
	var mine []pkgInfo
	for {
		var p pkgInfo
		if err := dec.Decode(&p); err == io.EOF {
			break
		} else if err != nil {
			panic(err)
		}
		exports[p.ImportPath] = p.Export
		if p.Module != nil && p.Module.Path == modPath {
			mine = append(mine, p)
		}
	}
	imp := importer.ForCompiler(fset, "gc", func(path string) (io.ReadCloser, error) {
		f, ok := exports[path]
		if !ok || f == "" {
			return nil, fmt.Errorf("no export for %s", path)
		}
		return os.Open(f)
	})
	for _, p := range mine {
		var fs []*ast.File
		for _, g := range p.GoFiles {
			fn := filepath.Join(p.Dir, g)
			f, err := parser.ParseFile(fset, fn, nil, parser.SkipObjectResolution)
			if err != nil {
				panic(err)
			}
			fs = append(fs, f)
			files[fn] = f
		}
		info := &types.Info{Uses: map[*ast.Ident]types.Object{}, Defs: map[*ast.Ident]types.Object{}, Types: map[ast.Expr]types.TypeAndValue{}}
		conf := types.Config{Importer: imp, Error: func(error) {}}
		tp, _ := conf.Check(p.ImportPath, fset, fs, info)
		for _, f := range fs {
			fileInf[fset.Position(f.Pos()).Filename] = info
			for _, d := range f.Decls {
				if fd, ok := d.(*ast.FuncDecl); ok {
					pos := fset.Position(fd.Name.Pos())
					decls[key{pos.Filename, pos.Line}] = fd
				}
			}
		}
		if tp != nil {
			sc := tp.Scope()
			for _, n := range sc.Names() {
				if tn, ok := sc.Lookup(n).(*types.TypeName); ok {
					if nt, ok := tn.Type().(*types.Named); ok {
						for i := 0; i < nt.NumMethods(); i++ {
							m := nt.Method(i)
							methods[m.Name()] = append(methods[m.Name()], m)
						}
					}
				}
			}
		}
	}

	var routes []route
	b, _ := io.ReadAll(mustOpen(os.Args[1]))
	_ = json.Unmarshal(b, &routes)
	root := os.Args[2]
	type out struct {
		route
		Writes, Reads, SQLFuncs, Topics, Audience, Checks []string
		Storage                                           bool
		RoleRefs                                          []string
	}
	var res []out
	for _, r := range routes {
		parts := strings.Split(r.Where, ":")
		fn := filepath.Join(root, parts[0])
		var line int
		fmt.Sscan(parts[1], &line)
		f := files[fn]
		if f == nil {
			res = append(res, out{route: r})
			continue
		}
		info := fileInf[fn]
		var start []ast.Node
		ast.Inspect(f, func(n ast.Node) bool {
			if ce, ok := n.(*ast.CallExpr); ok && fset.Position(ce.Pos()).Line <= line && fset.Position(ce.End()).Line >= line {
				if se, ok := ce.Fun.(*ast.SelectorExpr); ok && isVerb(se.Sel.Name) && fset.Position(se.Sel.Pos()).Line == line {
					for _, a := range ce.Args[1:] {
						start = append(start, a)
					}
					return false
				}
			}
			return true
		})
		w := &walker{roleRefs: map[string]bool{}, seen: map[ast.Node]bool{}, writes: map[string]bool{}, reads: map[string]bool{}, sqlf: map[string]bool{}, topics: map[string]bool{}, aud: map[string]bool{}, checks: map[string]bool{}}
		for _, s := range start {
			w.walk(s, info, 0)
		}
		res = append(res, out{route: r, Writes: keys(w.writes), Reads: keys(w.reads), SQLFuncs: keys(w.sqlf), Topics: keys(w.topics), Audience: keys(w.aud), Checks: keys(w.checks), Storage: w.storage, RoleRefs: keys(w.roleRefs)})
	}
	enc := json.NewEncoder(bufio.NewWriter(os.Stdout))
	bw := bufio.NewWriter(os.Stdout)
	enc = json.NewEncoder(bw)
	enc.SetIndent("", " ")
	_ = enc.Encode(res)
	bw.Flush()
}

func isVerb(s string) bool {
	switch s {
	case "GET", "POST", "PUT", "PATCH", "DELETE", "Any":
		return true
	}
	return false
}

func mustOpen(p string) *os.File {
	f, err := os.Open(p)
	if err != nil {
		panic(err)
	}
	return f
}

func keys(m map[string]bool) []string {
	var o []string
	for k := range m {
		o = append(o, k)
	}
	sort.Strings(o)
	return o
}

type walker struct {
	roleRefs                                 map[string]bool
	seen                                     map[ast.Node]bool
	writes, reads, sqlf, topics, aud, checks map[string]bool
	roles                                    map[string]bool
	storage                                  bool
}

func (w *walker) sql(s string) {
	for _, m := range sqlW.FindAllStringSubmatch(s, -1) {
		verb := strings.ToUpper(strings.Fields(m[1])[0])
		w.writes[verb+" "+strings.ToLower(m[2])] = true
	}
	for _, m := range sqlR.FindAllStringSubmatch(s, -1) {
		t := strings.ToLower(m[1])
		if !skipR[t] {
			w.reads[t] = true
		}
	}
	for _, m := range sqlF.FindAllString(s, -1) {
		w.sqlf[m] = true
	}
}

var roleLit = map[string]bool{"MANAGER": true, "BOARD_MEMBER": true, "AUDITOR": true, "STAFF": true, "SUPER_ADMIN": true, "OWNER": true, "TENANT": true, "PROXY": true}

var checkNames = map[string]bool{"isManagement": true, "isFinanceManager": true, "hasRole": true, "hasAnyRole": true, "isManager": true, "isManagementRole": true, "canManage": true, "residentScope": true, "reportRoles": true}

func (w *walker) walk(n ast.Node, info *types.Info, depth int) {
	if n == nil || w.seen[n] || depth > 12 {
		return
	}
	w.seen[n] = true
	ast.Inspect(n, func(x ast.Node) bool {
		switch v := x.(type) {
		case *ast.BasicLit:
			if v.Kind == token.STRING {
				w.sql(v.Value)
				if rv := strings.Trim(v.Value, "\"`"); roleLit[rv] {
					w.roleRefs[rv] = true
				}
			}
		case *ast.CallExpr:
			var callee *types.Func
			switch f := v.Fun.(type) {
			case *ast.Ident:
				callee, _ = info.Uses[f].(*types.Func)
			case *ast.SelectorExpr:
				callee, _ = info.Uses[f.Sel].(*types.Func)
			}
			if callee != nil {
				if sig, ok := callee.Type().(*types.Signature); ok {
					for i := 0; i < sig.Params().Len() && i < len(v.Args); i++ {
						prm := sig.Params().At(i)
						if prm.Name() == "to" && strings.Contains(prm.Type().String(), "Recipient") {
							if id, ok := v.Args[i].(*ast.Ident); !ok || id.Name != "nil" {
								w.aud["belirli kişi: "+recipientString(v.Args[i])] = true
								for _, a := range v.Args {
									w.walk(a, info, depth)
								}
								return false
							}
						}
					}
				}
			}
		case *ast.KeyValueExpr:
			if k, ok := v.Key.(*ast.Ident); ok && k.Name == "Topic" {
				w.topics[exprString(v.Value)] = true
			}
		case *ast.Ident:
			obj := info.Uses[v]
			switch o := obj.(type) {
			case *types.Const:
				if o.Val().Kind() == constant.String {
					sv := constant.StringVal(o.Val())
					w.sql(sv)
					if roleLit[sv] && strings.HasPrefix(o.Name(), "Role") {
						w.roleRefs[sv] = true
					}
				}
			case *types.Var:
				if o.Pkg() != nil && strings.HasPrefix(o.Pkg().Path(), modPath) && o.Parent() == o.Pkg().Scope() {
					w.follow(o.Pos(), depth)
				}
			case *types.Func:
				w.fn(o, depth)
			}
		}
		return true
	})
}

func (w *walker) fn(o *types.Func, depth int) {
	if o.Pkg() == nil || !strings.HasPrefix(o.Pkg().Path(), modPath) {
		return
	}
	p := o.Pkg().Path()
	if strings.HasSuffix(p, "/pkg/middleware") || strings.HasSuffix(p, "/pkg/audit") {
		if o.Name() != "RequireRole" && o.Name() != "AuditLog" {
			return
		}
		return
	}
	if strings.HasSuffix(p, "/pkg/notify") {
		switch o.Name() {
		case "Residents", "UnitResidents", "UnitUsers", "AssessmentPayers", "BlockNeighbors", "Tenants", "UnitOwners", "Managers", "Approvers", "Operations", "NotifyCharges":
			w.aud[o.Name()] = true
		}
		if o.Name() != "NotifyCharges" {
			return
		}
	}
	if strings.HasSuffix(p, "/pkg/storage") {
		w.storage = true
		return
	}
	if checkNames[o.Name()] {
		w.checks[o.Name()] = true
	}
	if sig, ok := o.Type().(*types.Signature); ok && sig.Recv() != nil {
		if _, isIface := sig.Recv().Type().Underlying().(*types.Interface); isIface {
			iface := sig.Recv().Type().Underlying().(*types.Interface)
			for _, m := range methods[o.Name()] {
				rt := m.Type().(*types.Signature).Recv().Type()
				if types.Implements(rt, iface) || types.Implements(types.NewPointer(rt), iface) {
					w.follow(m.Pos(), depth)
				}
			}
			return
		}
	}
	w.follow(o.Pos(), depth)
}

func (w *walker) follow(pos token.Pos, depth int) {
	p := fset.Position(pos)
	if fd, ok := decls[key{p.Filename, p.Line}]; ok {
		w.walk(fd, fileInf[p.Filename], depth+1)
		return
	}
	if f, ok := files[p.Filename]; ok {
		ast.Inspect(f, func(x ast.Node) bool {
			if vs, ok := x.(*ast.ValueSpec); ok && fset.Position(vs.Pos()).Line == p.Line {
				w.walk(vs, fileInf[p.Filename], depth+1)
				return false
			}
			return true
		})
	}
}

func exprString(e ast.Expr) string {
	switch v := e.(type) {
	case *ast.BasicLit:
		return strings.Trim(v.Value, "\"`")
	case *ast.BinaryExpr:
		return exprString(v.X) + exprString(v.Y)
	case *ast.Ident:
		return "{" + v.Name + "}"
	case *ast.SelectorExpr:
		return "{" + exprString(v.X) + "." + v.Sel.Name + "}"
	case *ast.CallExpr:
		return "{" + exprString(v.Fun) + "(…)}"
	case *ast.IndexExpr:
		return exprString(v.X) + "[…]"
	}
	return "{…}"
}

func recipientString(e ast.Expr) string {
	var parts []string
	ast.Inspect(e, func(x ast.Node) bool {
		if kv, ok := x.(*ast.KeyValueExpr); ok {
			if k, ok := kv.Key.(*ast.Ident); ok && k.Name == "UserID" {
				parts = append(parts, exprString(kv.Value))
			}
		}
		return true
	})
	if len(parts) == 0 {
		return exprString(e)
	}
	return strings.Join(parts, ", ")
}
