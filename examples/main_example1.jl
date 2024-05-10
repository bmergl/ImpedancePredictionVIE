using ImpedancePredictionVIE
using CompScienceMeshes
using Plots
using BEAST
using LinearAlgebra
using StaticArrays



geoname = "cube.geo"
geopath = "$(pkgdir(ImpedancePredictionVIE))/examples/$geoname"

meshname = "cube.msh"
meshpath = "$(pkgdir(ImpedancePredictionVIE))/examples/$meshname"

h = 2.0 # kleiner 0.2 sonst std
Ω, Γ, Γ_c, Γ_c_t, Γ_c_b, Γ_nc = geo2mesh(geopath, meshpath, h)

# Visu.mesh(Ω)
# Visu.mesh(Γ_c)
# Visu.mesh(Γ_c_t)
# Visu.mesh(Γ_c_b)
# Visu.mesh(Γ_nc)
# Visu.mesh(Γ)


# linearlag (dirichlet) auf Γ_c
topnodes = realnodes(Γ_c_t) # wichtig denn später z.B. 10V
bottomnodes = realnodes(Γ_c_b) # ""  z.B. 0V
dirichletnodes = append!(deepcopy(topnodes), bottomnodes)
y_d = lagrangec0d1(Γ, dirichletnodes, Val{3})
# INFO: dirichletnodes[i] gehört zu y_d.pos[i] also "Spannungsvektor": [10V 10V ..... 10V 0V 0V ..... 0V 0V]
#Visu.fnspos(y_d, Visu.mesh(Γ))



# linearlag auf Γ_nc
y = lagrangec0d1(Γ_nc, dirichlet = true) 
#Visu.fnspos(y, Visu.mesh(Γ))


# SWG auf Ω (ohne Γ_nc Flächen)
swgfaces = SWGfaces(Ω, Γ_nc) # Quadratische Komplexität ist extrem langsam!!!! ----> Octree???
X = nedelecd3d(Ω, Mesh(Ω.vertices, swgfaces))#X = nedelecd3d(Ω)

for fsh in X.fns
    if length(fsh) == 2
        c1 = fsh[1].coeff
        c2 = fsh[2].coeff
        @assert c1 == c2*(-1)
    end
end

ntrc = X -> BEAST.ntrace(X, Γ)
@show length(swgfaces)
#@assert length(X.pos) == length(swgfaces)
#ntrc(X).fns
#Visu.fnspos(X, Visu.mesh(Γ))
#Visu.fnspos(ntrc(X), Visu.mesh(Γ_c))

@show numfunctions(X)
@show numfunctions(y)
@show numfunctions(y_d)


## #########################################################


κ = x -> 1.0

τ, inv_τ = gen_tau_invtau(problemtype = :current, kappa = κ)
p = SVector(0.0,0.0,0.0)
τ(p)
inv_τ(p)
inv_τ_val = inv_τ(p)

#τ0 = 1.0
#χ(p)
#χ0
#χ_min_χ0I(p)
#χ(p) - χ0

# function gen_help(itau, tau0)
#     function help(x)
#         itaux = itau(x)
#         return itaux - 1/tau0
#     end
#     return help
# end
# help = gen_help(inv_τ, τ0)
# help(p)

# Anregung
u_top = ones(length(topnodes)) * 0.5  # Volle Symmetrie!
u_bottom = ones(length(bottomnodes)) * (-0.5)
ex = append!(deepcopy(u_top), u_bottom)



# Operatoren I: τ = const. => ΔΦ=0 und ΔΦ=-ΔΦ in den Greenschen Satz eingesetzt, was ja prinz. erl. sein sollte 
# TL_Γ = IPVIE1.tl_Γ()
# TL_ΓΓ = IPVIE1.tl_ΓΓ(alpha = 1.0, gammatype = Float64)

# TR_ΓΩ = IPVIE1.tr_ΓΩ(alpha = -1.0, gammatype = Float64, invtau = inv_τ)
# TR_ΓΓ = IPVIE1.tr_ΓΓ(alpha = 2.0, gammatype = Float64, invtau = inv_τ_val)

# BL_ΓΓ = IPVIE1.bl_ΓΓ(alpha = 1.0, gammatype = Float64) # !!! -(1/2)*Identity() SCHON EINGEFÜGT!!!!
# BL_ΩΓ = IPVIE1.bl_ΩΓ(alpha = -1.0, gammatype = Float64)   # n̂ richtung stimmt....

# BR_Ω =  IPVIE1.br_Ω(alpha = -1.0, invtau = inv_τ)
# BR_ΓΩ = IPVIE1.br_ΓΩ(alpha = -1.0, gammatype = Float64, invtau = inv_τ)
# BR_ΩΩ = IPVIE1.br_ΩΩ(alpha = 1.0, gammatype = Float64, invtau = inv_τ)
# BR_ΓΓ = IPVIE1.br_ΓΓ(alpha = 2.0, gammatype = Float64, invtau = inv_τ_val)
# BR_ΩΓ = IPVIE1.br_ΩΓ(alpha = -2.0, gammatype = Float64, invtau = inv_τ)
#Ergebnisse sind eine Katastrophe...
# Merkwürdig: BR_ΓΓ, BR_ΩΓ, TR_ΓΓ weglassen (also die mit faktor 2.0) => Vektorfeld im inneren schön!!! 



# Operatoren II: τ = const. => ΔΦ=0 und ΔΦ unverändert gelassen
# TL_Γ = IPVIE1.tl_Γ()
# TL_ΓΓ = IPVIE1.tl_ΓΓ(alpha = 1.0, gammatype = Float64)

# TR_ΓΩ = IPVIE1.tr_ΓΩ(alpha = 1.0, gammatype = Float64, invtau = inv_τ)
# TR_ΓΓ = 0.0*IPVIE1.tr_ΓΓ(alpha = 2.0, gammatype = Float64, invtau = inv_τ_val)

# BL_ΓΓ = IPVIE1.bl_ΓΓ(alpha = 1.0, gammatype = Float64) # !!! -(1/2)*Identity() SCHON EINGEFÜGT!!!!
# BL_ΩΓ = IPVIE1.bl_ΩΓ(alpha = -1.0, gammatype = Float64)   # n̂ richtung stimmt....

# BR_Ω =  -IPVIE1.br_Ω(alpha = -1.0, invtau = inv_τ)
# BR_ΓΩ = IPVIE1.br_ΓΩ(alpha = 1.0, gammatype = Float64, invtau = inv_τ)
# BR_ΩΩ = IPVIE1.br_ΩΩ(alpha = -1.0, gammatype = Float64, invtau = inv_τ)
# BR_ΓΓ = 0.0*IPVIE1.br_ΓΓ(alpha = 2.0, gammatype = Float64, invtau = inv_τ_val)
# BR_ΩΓ = 0.0*IPVIE1.br_ΩΓ(alpha = -2.0, gammatype = Float64, invtau = inv_τ)
# Ergebnisse sind eine Katastrophe...


#Operatoren: τ = const. - recht gute Kombi - aber keine passende Herleitung
TL_Γ =  IPVIE1.tl_Γ()
TL_ΓΓ = IPVIE1.tl_ΓΓ(alpha = 1.0, gammatype = Float64) # !!! -(1/2)*Identity() SCHON EINGEFÜGT!!!!

TR_ΓΩ = 1.0*IPVIE1.tr_ΓΩ(alpha = 1.0, gammatype = Float64, invtau = inv_τ)
TR_ΓΓ = 0.0*IPVIE1.tr_ΓΓ(alpha = 1.0, gammatype = Float64, invtau = inv_τ_val) # SL GEHÖRT VMTL NICHT DAZU

BL_ΓΓ = IPVIE1.bl_ΓΓ(alpha = -1.0, gammatype = Float64) # !!! -(1/2)*Identity() SCHON EINGEFÜGT!!!!
BL_ΩΓ = IPVIE1.bl_ΩΓ(alpha = 1.0, gammatype = Float64)   # n̂ richtung stimmt....

BR_Ω =  IPVIE1.br_Ω(alpha = 1.0, invtau = inv_τ) #(1/2)* würde passendes J liefern...
BR_ΓΩ = 1.0*IPVIE1.br_ΓΩ(alpha = 1.0, gammatype = Float64, invtau = inv_τ)
BR_ΩΩ = -1.0*IPVIE1.br_ΩΩ(alpha = 1.0, gammatype = Float64, invtau = inv_τ)
BR_ΓΓ = 0.0*IPVIE1.br_ΓΓ(alpha = 2.0, gammatype = Float64, invtau = inv_τ_val)
BR_ΩΓ = 0.0*IPVIE1.br_ΩΓ(alpha = -2.0, gammatype = Float64, invtau = inv_τ)



TEST = IPVIE1.br_Ω(alpha = 1.0, invtau = x -> 1.0)
@assert norm(assemble(Identity(),X,X)-assemble(TEST,X,X)) < 1e-12
@assert norm(assemble(Identity(),y,ntrc(X))-assemble(TEST,y,ntrc(X))) < 1e-12

# LHS
@hilbertspace k l # Zeilen    k -> a      l -> bvec
@hilbertspace j m # Spalten   j -> a      m -> bvec

lhs = @varform(
    TL_Γ[k,j] + TL_ΓΓ[k,j] +
    TR_ΓΩ[k,m] + TR_ΓΓ[k,ntrc(m)] +
    BL_ΓΓ[ntrc(l),j] + BL_ΩΓ[l,j] +
    BR_Ω[l,m] + BR_ΩΩ[l,m] + BR_ΓΩ[ntrc(l),m] + BR_ΓΓ[ntrc(l),ntrc(m)] + BR_ΩΓ[l,ntrc(m)]
)


lhsd = @discretise lhs k∈y l∈X j∈y m∈X
lhsd_test = lhsd.test_space_dict
lhsd_trial = lhsd.trial_space_dict
testSpace_lhs = BEAST._spacedict_to_directproductspace(lhsd_test)
trialSpace_lhs = BEAST._spacedict_to_directproductspace(lhsd_trial)
M = assemble(lhs, testSpace_lhs, trialSpace_lhs)
S = Matrix(M)


# RHS
#@hilbertspace k l # Zeilen
@hilbertspace n # Spalten, !!! Nur eine Blockspalte

rhs = @varform( # Vorlage für nicht-quadratische Matrix ...
    -TL_Γ[k,n] -TL_ΓΓ[k,n] +
    -BL_ΓΓ[ntrc(l),n] -BL_ΩΓ[l,n]
)

rhsd = @discretise rhs k∈y l∈X n∈y_d
rhsd_test = rhsd.test_space_dict
rhsd_trial = rhsd.trial_space_dict
testSpace_rhs = BEAST._spacedict_to_directproductspace(rhsd_test)
trialSpace_rhs = BEAST._spacedict_to_directproductspace(rhsd_trial)
R = Matrix(assemble(rhs, testSpace_rhs, trialSpace_rhs))


# S*u = R*ex
b = R*ex
u = S \ b
@assert norm(S*u - b) < 1e-10



# Stomdichte
range_ = range(-0.49,stop=0.49,length=9)
points = [point(x,y,z) for x in range_ for y in range_ for z in range_]
J_MoM = BEAST.grideval(points, u[length(y)+1:end], X)#, type=Float64)
@assert length(u[length(y)+1:end]) == length(X.fns)

display(Visu.fieldplot(points, J_MoM, 1.0, Visu.mesh(Γ_c)))


# Stromdichte in Ebene z0
range_xy = range(-0.49,stop=0.49,length=9)
z0 = 0.0
points2 = [point(x,y,z0) for x in range_xy for y in range_xy]
J_MoM2 = BEAST.grideval(points2, u[length(y)+1:end], X)
@show sum(norm.(J_MoM2))/length(J_MoM2)
#PRÜFE WERTE VON u[1:length(y)] denn diese müssen den Spannung auf Γ_nc
# als ZWISCHEN den ELEKTRODENSPANNUNGEN!
@show maximum(u[1:length(y)])
@show minimum(u[1:length(y)])

Jallx, Jally, Jallz = pointlist2xyzlist(J_MoM2)
#[Jallz[i] >= 0.0 && error("") for i in 1:1:length(Jallz)]
@show sum(Jallz)/length(Jallz)
""
##
@show sum(abs.(Jallx))/length(Jallx) # Ist Liniendurchschnitt 
@show sum(abs.(Jally))/length(Jally) # Ist Liniendurchschnitt
@show sum(Jallx)/length(Jallx) # Ist Liniendurchschnitt
@show sum(Jally)/length(Jally) # Ist Liniendurchschnitt


# ERGEBNISSE:
# J_z - Komponente ist in der Nähe der Kontaktflächen unphysikalisch! 
#      d.h. +/- Sprünge benachbarter Zellen...

# Doppelte Leitfähigkeit => Doppelter Strom!!! STIMMT
# Doppelte Spannung => Doppelter Strom!!! STIMMT
# Halbe Leitfähigkeit => Halber Strom!!! STIMMT

""
##
# Richtungstest J an Übergängen der swgfaces
for face in swgfaces
    patch = simplex(Ω.vertices[face]) 
    n = patch.normals[1]
    c = CompScienceMeshes.center(patch) # mp
    p = cartesian(c)
    p1 = p + n*1e-7
    p2 = p - n*1e-7
    J_list = BEAST.grideval([p1,p2], u[length(y)+1:end], X)
    
    J1 = J_list[1]
    J2 = J_list[2]
    J1n = dot(J1,n)
    J2n = dot(J2,n)

    if (J1n != 0.0) && (J2n != 0.0)
        @assert sign(J1n) == sign(J1n)
    end
end

""
##
t



# S1 = BEAST._spacedict_to_directproductspace(lhs.test_space)
# S2 = BEAST._spacedict_to_directproductspace(lhs.trial_space)
# assemble(lhs,S1,S2)

# vie = @discretise lhs k∈y, l∈X, j∈y, m∈X, n∈y_d


#     ==
#     (-TL_Γ-TL_ΓΓ)[k,n] +                 #??? Wie bekommt man da Matrix*gegebenen Vektor hinein??? 
#     (-BL_ΓΓ)[ntrc(l),n] + (-BL_ΩΓ)[l,n], #??? Wie bekommt man da Matrix*gegebenen Vektor hinein??? 
#     k∈y, l∈X, j∈y, m∈X, n∈y_d
# )
# u = solve(vie)
#@assert lengths...


#vie = @discretise( )




#a1, a2, a3 = assemblydata(X)



##
# t1=[[u,v,w] for w in 0.0:0.09:1 for v in 0:0.09:1-w for u in 0:0.09:1-v-w]

# range_ = collect(range(start=0.0, stop=1.0, length=3))
# bary_list = [[u, v, w] for u in range_ for v in range_-u for w in range_-u-v]

##

s1 = simplex(Ω.vertices[Ω.faces[3]])

plt = Visu.mesh(Γ_c_t)
plt = Visu.simplex(plt, s1)
plt = Visu.add1(plt, s1, refspace(X))


##
plt=Visu.mesh(Ω)

Visu.add1(plt, s1, refspace(X))


##



@show length(skeleton(Ω,2))
@show numfunctions(X)
#y = boundary(Ω)

Visu.mesh(Ω)

r=refspace(X)
p=point(0.0,0.1,0.3)
#r(p)
##

barycoord1=point(0.0,0.1,0.3)
@assert norm(barycoord1) <= 1.0 
s1 = simplex(Ω.vertices[Ω.faces[3]])
n1 = neighborhood(s1,barycoord1)

# jetzt kann man r(CSM-MP) anwenden
r(n1)[4]






# α, α′ = 1/η, 1/η′
# vie = @discretise(
#     (η*T+η′*T′)[k,j] -      (K+K′)[k,m] +
#          (K+K′)[l,j] + (α*T+α′*T′)[l,m] == -e[k] - h[l],
#     j∈X, m∈X, k∈X, l∈X)

# u = solve(vie)
#@assert lengths...









##


# plotly()
# plt = plot(legend=false, xlims=(-1,1), ylims=(-1,1), zlims=(-1,1), size=(850,850))

# # Zeichnen Sie einen Pfeil von Punkt a nach Punkt b
# pnt = [0.1,-0.4,0.3]
# dir = [-0.3,-0.3,0.8]

# Visu.draw_arrow!(plt, pnt, dir; scale = 0.1, arrcolor = "blue", arrwidth = 3)

# # Zeigen Sie den Plot an
# range_ = range(start=0.0, stop=1.0, length=3)




##






default(fmt=:svg)
default(fmt=:png)

###############################################################################
# ADD THIS BLOCK TO REMOVE SVG FROM LIST OF "DISPLAYABLE_MIMES":
# pos = findfirst((x)->(x=="image/svg+xml"), VSCodeServer.DISPLAYABLE_MIMES)
# if !isnothing(pos)
#     popat!(VSCodeServer.DISPLAYABLE_MIMES, pos)
#     println("Popped!")
# end
###############################################################################





#test_elements, tad, a1= assemblydata(y_d)
dirichlet_n2f(y_d, dirichletnodes)

y_d.geo.vertices[dirichletnodes]
y_d.geo.vertices
#test_elements, tad, a1= assemblydata(X)
# y_d 116 fns => die (n,val) Einträge der tad.data Matrix haben n=(0),1,2,...,116 - 116 ist die Zahl der dirichletnodes
# also 284 Dreiecke
dirichletnodes[100]


tad.data[1,1,1]

length(y_d.fns)
length(realvertices(Γ))
length(Γ_c.faces)
length(Γ_nc.faces)
#length(tad.data)

max=0
min=1e30
for el in tad.data #! ist matrix!!!!
    @show el
    max <= el[1] && (max = el[1])
    min >= el[1] && (min = el[1])
end
max
min


##



#lhs = eq.equation.lhs
#rhs = eq.equation.rhs

@hilbertspace a1
@hilbertspace a2

eq1 = @varform BR_ΩΓ[a1,ntrc(a2)] + BR_ΓΓ[ntrc(a1),ntrc(a2)] + (BR_Ω+BR_ΩΩ)[a1,a2]
vie1 = @discretise eq1 a1∈X a2∈X 
tedic=vie1.test_space_dict
trdic=vie1.trial_space_dict
S1 = BEAST._spacedict_to_directproductspace(tedic)
S2 = BEAST._spacedict_to_directproductspace(trdic)
assemble(eq1, S1, S2)




# # LHS Assemble Test 
# assemble(TL_Γ, y, y) # ist 1/2 I
# assemble(TL_ΓΓ, y, y)

# assemble(TR_ΓΓ, y, ntrc(X))
# assemble(TR_ΓΩ, y, X)

# assemble(BL_ΓΓ, ntrc(X), y)
# assemble(BL_ΩΓ, X, y)
# #
# assemble(BR_Ω, X, X)
# assemble(BR_ΓΓ, ntrc(X), ntrc(X))
# assemble(BR_ΩΓ, X, ntrc(X))
# assemble(BR_ΓΩ, ntrc(X), X)
# assemble(BR_ΩΩ, X, X)

# # RHS Assemble Test, später noch * geg dirichlet spannungsvektor
# assemble(-TL_Γ, y, y_d)
# assemble(-TL_ΓΓ, y, y_d)

# assemble(-BL_ΓΓ, ntrc(X), y_d)
# assemble(-BL_ΩΓ, X, y_d)