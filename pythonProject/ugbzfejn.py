# ============================================================
#  3D THERMAL SIMULATION - 10,000 L TANK
#  3D Finite Differences + Play Button to start the simulation
# ============================================================
import matplotlib
matplotlib.use('TkAgg')  # or 'Qt5Agg' if you have PyQt5 installed
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.animation as animation
from matplotlib import cm
from matplotlib.widgets import Button
from mpl_toolkits.mplot3d import Axes3D

# ─── PARAMETERS ─────────────────────────────────────────────
rho    = 100.0
Cp     = 4186.0
lam    = 0.6
T_init = 15.0
T_ext  = 10.0
U_wall = 0.5
Lx, Ly, Lz = 2.5, 2.0, 2.0
NX, NY, NZ  = 15, 15, 10
dx, dy, dz  = Lx/NX, Ly/NY, Lz/NZ
dt = 60.0
t_end_h = 500
steps   = int(t_end_h * 3600 / dt)
frames_every = 30

# ─── INITIALISATION ──────────────────────────────────────────
T = np.full((NZ, NY, NX), T_init)
x = np.linspace(0, Lx, NX)
y = np.linspace(0, Ly, NY)
z = np.linspace(0, Lz, NZ)
X2, Y2 = np.meshgrid(x, y)
X3, Z3 = np.meshgrid(x, z)
Y4, Z4 = np.meshgrid(y, z)
vmin, vmax = T_ext - 0.2, T_init + 0.2

times_rec, T_moy_rec = [0.0], [T_init]

# ─── ANIMATION STATE ────────────────────────────────────────
running = [False]
ani_obj = [None]
step_counter = [0]

# ─── FIGURE ──────────────────────────────────────────────────
fig = plt.figure(figsize=(14, 6))
fig.subplots_adjust(bottom=0.15)

ax3 = fig.add_subplot(121, projection='3d')
axP = fig.add_subplot(122)

# Curve
line_T, = axP.plot([], [], 'b-', linewidth=2, label='Avg temperature')
axP.axhline(T_ext, color='r', linestyle='--', linewidth=1.5, label=f'Ext. temp ({T_ext}°C)')
axP.set_xlim(0, t_end_h)
axP.set_ylim(T_ext - 0.5, T_init + 0.5)
axP.set_xlabel('Time (h)')
axP.set_ylabel('Temperature (°C)')
axP.set_title('Cooling')
axP.legend(); axP.grid(True, alpha=0.3)

# Colorbar
mappable = cm.ScalarMappable(cmap='jet')
mappable.set_clim(vmin, vmax)
fig.colorbar(mappable, ax=ax3, shrink=0.5, label='°C')

# Waiting message on the 3D plot
ax3.set_xlabel('X (m)'); ax3.set_ylabel('Y (m)'); ax3.set_zlabel('Z (m)')
ax3.set_title('Press ▶ Play to start')
ax3.set_xlim(0, Lx); ax3.set_ylim(0, Ly); ax3.set_zlim(0, Lz)

# ─── BUTTONS ────────────────────────────────────────────────
ax_btn_play  = fig.add_axes([0.38, 0.03, 0.10, 0.06])
ax_btn_pause = fig.add_axes([0.50, 0.03, 0.10, 0.06])
ax_btn_reset = fig.add_axes([0.62, 0.03, 0.10, 0.06])

btn_play  = Button(ax_btn_play,  '▶  Play',  color='#4CAF50', hovercolor='#66BB6A')
btn_pause = Button(ax_btn_pause, '⏸  Pause', color='#FF9800', hovercolor='#FFB74D')
btn_reset = Button(ax_btn_reset, '↺  Reset', color='#F44336', hovercolor='#EF9A9A')

for btn in [btn_play, btn_pause, btn_reset]:
    btn.label.set_fontsize(10)
    btn.label.set_fontweight('bold')

# ─── STEP FUNCTION ──────────────────────────────────────────
def do_steps(T, n):
    ax = lam / (rho * Cp * dx**2)
    ay = lam / (rho * Cp * dy**2)
    az = lam / (rho * Cp * dz**2)
    for _ in range(n):
        Tn = T.copy()
        Tn[1:-1,1:-1,1:-1] = T[1:-1,1:-1,1:-1] + dt * (
            ax*(T[1:-1,1:-1,2:] + T[1:-1,1:-1,:-2] - 2*T[1:-1,1:-1,1:-1]) +
            ay*(T[1:-1,2:,1:-1] + T[1:-1,:-2,1:-1] - 2*T[1:-1,1:-1,1:-1]) +
            az*(T[2:,1:-1,1:-1] + T[:-2,1:-1,1:-1] - 2*T[1:-1,1:-1,1:-1])
        )
        for idx, d in [
            ((slice(None),slice(None), 0), dx),
            ((slice(None),slice(None),-1), dx),
            ((slice(None), 0,slice(None)), dy),
            ((slice(None),-1,slice(None)), dy),
            (( 0,slice(None),slice(None)), dz),
            ((-1,slice(None),slice(None)), dz),
        ]:
            Tn[idx] = T[idx] + dt * U_wall * (T_ext - T[idx]) / (rho * Cp * d)
        T = Tn
    return T

# ─── ANIMATION ──────────────────────────────────────────────
def update(frame):
    global T
    if not running[0]:
        return []

    T = do_steps(T, frames_every)
    step_counter[0] += frames_every
    elapsed_s = step_counter[0] * dt
    elapsed_h = elapsed_s / 3600
    Tavg = T.mean()
    A = 2*(Lx*Ly + Lx*Lz + Ly*Lz)
    Q  = U_wall * A * (Tavg - T_ext)

    times_rec.append(elapsed_h)
    T_moy_rec.append(Tavg)
    line_T.set_data(times_rec, T_moy_rec)

    ax3.cla()
    kz, jy, ix = NZ//2, NY//2, NX//2

    ax3.plot_surface(X2, Y2, np.full_like(X2, z[kz]),
                     facecolors=cm.jet((T[kz,:,:]-vmin)/(vmax-vmin)),
                     alpha=0.85, shade=False)
    ax3.plot_surface(X3, np.full_like(X3, y[jy]), Z3,
                     facecolors=cm.jet((T[:,jy,:]-vmin)/(vmax-vmin)),
                     alpha=0.85, shade=False)
    ax3.plot_surface(np.full_like(Y4, x[ix]), Y4, Z4,
                     facecolors=cm.jet((T[:,:,ix]-vmin)/(vmax-vmin)),
                     alpha=0.85, shade=False)

    ax3.set_xlabel('X (m)'); ax3.set_ylabel('Y (m)'); ax3.set_zlabel('Z (m)')
    ax3.set_title(
        f'Distribution de température\n'
        f'Temps : {elapsed_h:.1f} h | '
        f'T moy : {Tavg:.2f} °C | '
        f'Flux : {Q:.0f} W'
    )
    ax3.set_xlim(0,Lx); ax3.set_ylim(0,Ly); ax3.set_zlim(0,Lz)
    return []

# ─── CALLBACKS BOUTONS ──────────────────────────────────────
def on_play(event):
    running[0] = True

def on_pause(event):
    running[0] = False

def on_reset(event):
    global T
    running[0] = False
    T = np.full((NZ, NY, NX), T_init)
    step_counter[0] = 0
    times_rec.clear(); times_rec.append(0.0)
    T_moy_rec.clear(); T_moy_rec.append(T_init)
    line_T.set_data([], [])
    ax3.cla()
    ax3.set_xlabel('X (m)'); ax3.set_ylabel('Y (m)'); ax3.set_zlabel('Z (m)')
    ax3.set_title('Appuie sur ▶ Play pour démarrer')
    ax3.set_xlim(0,Lx); ax3.set_ylim(0,Ly); ax3.set_zlim(0,Lz)
    fig.canvas.draw()

btn_play.on_clicked(on_play)
btn_pause.on_clicked(on_pause)
btn_reset.on_clicked(on_reset)

# ─── LANCEMENT (animation tourne en continu, Play/Pause contrôle l'update) ──
n_frames = steps // frames_every
ani_obj[0] = animation.FuncAnimation(fig, update, frames=n_frames,
                                      interval=100, blit=False, repeat=False)

plt.tight_layout(rect=[0, 0.12, 1, 1])
plt.show()