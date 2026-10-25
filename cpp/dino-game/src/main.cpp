#include <windows.h>
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <random>
#include <string>
#include <vector>

namespace {
constexpr int W = 960, H = 360;
constexpr float ground = 278.f;
struct Obstacle { float x, y, w, h; bool bird; };
std::mt19937 rng(std::random_device{}());
float random(float a, float b) { return std::uniform_real_distribution<float>(a,b)(rng); }
enum class Mode { Ready, Running, Over };
Mode mode = Mode::Ready;
std::vector<Obstacle> obstacles;
float y = ground, velocity = 0, distance = 0, spawn = 1.2f, animation = 0;
int high = 0;
bool down = false, jumpHeld = false, paused = false;
std::wstring savePath;
COLORREF ink = RGB(83,83,83), paper = RGB(250,250,247);

void saveHigh() {
    FILE* f = nullptr;
    if (_wfopen_s(&f, savePath.c_str(), L"w") == 0 && f) {
        fprintf(f, "%d", high); fclose(f);
    }
}
void reset() {
    obstacles.clear(); y = ground; velocity = 0; distance = 0;
    spawn = 1.25f; animation = 0; paused = false; mode = Mode::Running;
}
void jump() {
    if (mode != Mode::Running) reset();
    if (!paused && y >= ground - .1f) { velocity = -660; down = false; }
}
void update(float dt) {
    if (mode != Mode::Running || paused) return;
    animation += dt;
    float speed = 330 + std::min(distance * .014f, 330.f);
    distance += speed * dt;
    velocity += (down && y < ground ? 2600.f : 1850.f) * dt;
    y = std::min(ground, y + velocity * dt);
    if (y == ground) velocity = 0;
    spawn -= dt;
    if (spawn <= 0) {
        bool bird = distance > 3500 && random(0,1) < .25f;
        float height = bird ? 28.f : random(38,61);
        float width = bird ? 44.f : (random(0,1) < .35f ? 44.f : 24.f);
        float bottom = bird ? ground - (random(0,1) < .5f ? 28.f : 62.f) : ground;
        obstacles.push_back({W + 20.f, bottom-height, width, height, bird});
        spawn = random(1.05f,1.65f) * 330.f / speed + .38f;
    }
    bool duck = down && y == ground;
    float dh = duck ? 26.f : 48.f, dw = duck ? 58.f : 40.f;
    for (auto& o : obstacles) {
        o.x -= speed * dt;
        if (112 + dw - 7 > o.x + 5 && 112 + 7 < o.x + o.w - 5 &&
            y - 5 > o.y + 4 && y - dh + 6 < o.y + o.h - 4) {
            mode = Mode::Over;
            high = std::max(high, static_cast<int>(distance / 10)); saveHigh();
        }
    }
    obstacles.erase(std::remove_if(obstacles.begin(), obstacles.end(), [](const auto& o) {
        return o.x + o.w < -20;
    }), obstacles.end());
}
void rect(HDC dc, float x, float yy, float w, float h, COLORREF color) {
    RECT r{static_cast<LONG>(x),static_cast<LONG>(yy),static_cast<LONG>(x+w),static_cast<LONG>(yy+h)};
    HBRUSH brush = CreateSolidBrush(color); FillRect(dc,&r,brush); DeleteObject(brush);
}
void label(HDC dc, const std::wstring& s, int x, int yy, int size, COLORREF color, bool centered = false) {
    HFONT font = CreateFontW(size,0,0,0,FW_NORMAL,FALSE,FALSE,FALSE,DEFAULT_CHARSET,
        OUT_DEFAULT_PRECIS,CLIP_DEFAULT_PRECIS,ANTIALIASED_QUALITY,FIXED_PITCH,L"Consolas");
    auto old = SelectObject(dc,font); SetTextColor(dc,color); SetBkMode(dc,TRANSPARENT);
    SetTextAlign(dc, centered ? TA_CENTER : TA_LEFT);
    TextOutW(dc,x,yy,s.c_str(),static_cast<int>(s.size()));
    SelectObject(dc,old); DeleteObject(font);
}
void dino(HDC dc) {
    float x = 112;
    bool duck = down && y == ground && mode == Mode::Running;
    int step = static_cast<int>(animation * 12) % 2;
    if (duck) {
        rect(dc,x,y-25,44,18,ink); rect(dc,x+35,y-29,25,15,ink);
        rect(dc,x+51,y-26,3,3,paper);
        rect(dc,x+7,y-9,6,step?5.f:9.f,ink); rect(dc,x+32,y-9,6,step?9.f:5.f,ink);
        rect(dc,x-8,y-29,12,9,ink);
    } else {
        rect(dc,x+17,y-48,25,23,ink); rect(dc,x+20,y-27,14,12,ink);
        rect(dc,x+6,y-31,23,21,ink); rect(dc,x,y-26,12,12,ink);
        rect(dc,x-7,y-34,7,17,ink); rect(dc,x+29,y-21,10,4,ink);
        rect(dc,x+36,y-18,3,7,ink); rect(dc,x+34,y-44,3,3,paper);
        rect(dc,x+31,y-32,11,3,paper);
        bool run = mode == Mode::Running && y == ground;
        rect(dc,x+8,y-12,6,run&&step?7.f:12.f,ink); rect(dc,x+22,y-12,6,run&&!step?7.f:12.f,ink);
        rect(dc,x+8,y-3,10,3,ink); rect(dc,x+22,y-3,10,3,ink);
    }
}
void scene(HDC dc) {
    rect(dc,0,0,W,H,paper);
    label(dc,L"D I N O   R U N",28,23,18,ink);
    wchar_t score[80]; swprintf_s(score,L"HI %05d   %05d",high,static_cast<int>(distance/10));
    label(dc,score,690,24,20,ink);
    for (int i=0;i<5;++i) {
        float x = std::fmod(170.f + i*227.f - distance*.13f,1150.f);
        if (x < -80) x += 1150;
        float cy = 90.f + (i%3)*27;
        COLORREF cloud = RGB(218,218,211);
        rect(dc,x,cy,54,2,cloud); rect(dc,x+9,cy-8,35,2,cloud);
        rect(dc,x+17,cy-16,16,2,cloud); rect(dc,x+9,cy-8,2,8,cloud);
        rect(dc,x+43,cy-8,2,8,cloud);
    }
    rect(dc,0,ground,W,2,ink);
    for (int i=0;i<36;++i) {
        float x = std::fmod(i*37.f-distance,1332.f); if (x<0) x+=1332;
        rect(dc,x,ground+8+(i%3)*5,3+(i%4)*3.f,1,RGB(160,160,152));
    }
    for (const auto& o: obstacles) {
        if (o.bird) {
            rect(dc,o.x+10,o.y+10,27,12,ink); rect(dc,o.x,o.y+11,14,5,ink);
            float wingY = static_cast<int>(animation*8)%2 ? o.y : o.y+18;
            rect(dc,o.x+21,wingY,9,14,ink); rect(dc,o.x+35,o.y+8,9,5,ink);
        } else {
            rect(dc,o.x+9,o.y,10,o.h,ink);
            rect(dc,o.x,o.y+12,6,20,ink); rect(dc,o.x,o.y+27,16,6,ink);
            rect(dc,o.x+21,o.y+7,6,19,ink); rect(dc,o.x+15,o.y+21,12,6,ink);
            if (o.w>30) {
                rect(dc,o.x+32,o.y+12,9,o.h-12,ink);
                rect(dc,o.x+27,o.y+25,7,6,ink);
            }
        }
    }
    dino(dc);
    if (mode == Mode::Ready) {
        label(dc,L"READY TO RUN?",W/2,139,28,ink,true);
        label(dc,L"Press SPACE or click to start",W/2,178,17,ink,true);
    } else if (mode == Mode::Over) {
        rect(dc,310,125,340,94,paper);
        label(dc,L"G A M E  O V E R",W/2,137,27,ink,true);
        label(dc,L"SPACE / R / click to retry",W/2,180,17,ink,true);
    } else if (paused) {
        label(dc,L"PAUSED",W/2,140,28,ink,true);
    }
    label(dc,L"SPACE / UP  jump     DOWN  duck     P  pause     ESC  quit",W/2,322,16,RGB(130,130,123),true);
}
LRESULT CALLBACK windowProc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp) {
    switch(msg) {
    case WM_KEYDOWN:
        if (wp==VK_ESCAPE) DestroyWindow(hwnd);
        if ((wp==VK_SPACE || wp==VK_UP) && !jumpHeld) { jumpHeld=true; jump(); }
        if (wp==VK_DOWN) down=true;
        if (wp=='R' && !(lp & (1LL<<30))) reset();
        if (wp=='P' && !(lp & (1LL<<30)) && mode==Mode::Running) paused=!paused;
        return 0;
    case WM_KEYUP:
        if (wp==VK_SPACE || wp==VK_UP) {
            jumpHeld=false; if (velocity < -270) velocity=-270;
        }
        if (wp==VK_DOWN) down=false;
        return 0;
    case WM_LBUTTONDOWN: jump(); return 0;
    case WM_KILLFOCUS: down=false; jumpHeld=false; if(mode==Mode::Running) paused=true; return 0;
    case WM_ERASEBKGND: return 1;
    case WM_PAINT: {
        PAINTSTRUCT ps; HDC dc=BeginPaint(hwnd,&ps);
        HDC mem=CreateCompatibleDC(dc); HBITMAP bmp=CreateCompatibleBitmap(dc,W,H);
        auto old=SelectObject(mem,bmp); scene(mem);
        RECT client; GetClientRect(hwnd,&client);
        StretchBlt(dc,0,0,client.right,client.bottom,mem,0,0,W,H,SRCCOPY);
        SelectObject(mem,old); DeleteObject(bmp); DeleteDC(mem); EndPaint(hwnd,&ps); return 0;
    }
    case WM_DESTROY: PostQuitMessage(0); return 0;
    }
    return DefWindowProcW(hwnd,msg,wp,lp);
}
}
int WINAPI wWinMain(HINSTANCE instance,HINSTANCE,PWSTR,int show) {
    wchar_t local[MAX_PATH];
    DWORD n=GetEnvironmentVariableW(L"LOCALAPPDATA",local,MAX_PATH);
    if(n>0 && n<MAX_PATH) {
        savePath=std::wstring(local)+L"\\DinoRunner"; CreateDirectoryW(savePath.c_str(),nullptr);
        savePath+=L"\\highscore.txt";
    } else savePath=L"dino-highscore.txt";
    FILE* f=nullptr;
    if(_wfopen_s(&f,savePath.c_str(),L"r")==0 && f) {
        if(fscanf_s(f,"%d",&high)!=1 || high<0) high=0; fclose(f);
    }
    SetProcessDPIAware();
    WNDCLASSW wc{}; wc.lpfnWndProc=windowProc; wc.hInstance=instance;
    wc.lpszClassName=L"DinoRunnerWindow"; wc.hCursor=LoadCursor(nullptr,IDC_ARROW);
    RegisterClassW(&wc);
    RECT bounds{0,0,W,H}; DWORD style=WS_OVERLAPPEDWINDOW & ~WS_MAXIMIZEBOX & ~WS_THICKFRAME;
    AdjustWindowRect(&bounds,style,FALSE);
    HWND hwnd=CreateWindowW(wc.lpszClassName,L"Dino Run",style,CW_USEDEFAULT,CW_USEDEFAULT,
        bounds.right-bounds.left,bounds.bottom-bounds.top,nullptr,nullptr,instance,nullptr);
    if(!hwnd) return 1;
    ShowWindow(hwnd,show);
    LARGE_INTEGER freq,last; QueryPerformanceFrequency(&freq); QueryPerformanceCounter(&last);
    double accumulator=0;
    for (;;) {
        MSG msg;
        while(PeekMessageW(&msg,nullptr,0,0,PM_REMOVE)) {
            if(msg.message==WM_QUIT) return 0;
            TranslateMessage(&msg); DispatchMessageW(&msg);
        }
        LARGE_INTEGER now; QueryPerformanceCounter(&now);
        accumulator+=std::min(.1,static_cast<double>(now.QuadPart-last.QuadPart)/freq.QuadPart);
        last=now;
        while(accumulator>=1.0/120) { update(1.f/120); accumulator-=1.0/120; }
        InvalidateRect(hwnd,nullptr,FALSE); UpdateWindow(hwnd); Sleep(8);
    }
}
