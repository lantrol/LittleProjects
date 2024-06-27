import pygame
import sys
import math
import numpy as np

BLACK = (0, 0, 0)
WHITE = (200, 200, 200)
WINDOW_HEIGHT = 800
WINDOW_WIDTH = 800

pygame.init()
SCREEN = pygame.display.set_mode((WINDOW_WIDTH, WINDOW_HEIGHT))
CLOCK = pygame.time.Clock()

def main():
    dt = CLOCK.tick(60)/1000
    grid = EulerGrid(10)
    print(grid.walls.shape)
    print(grid.walls)
    while True:
        SCREEN.fill(BLACK)
        #drawGrid()
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()

        grid.updateVel(dt)
        grid.divergence(dt)
        grid.advection(dt)
        grid.draw()

        pygame.display.flip()
        #pygame.display.update()
        dt = CLOCK.tick(60)/1000

# def drawGrid():
#     blockSize = 20
#     for x in range(0, WINDOW_WIDTH, blockSize):
#         for y in range(0, WINDOW_HEIGHT, blockSize):
#             rect = pygame.Rect(x, y, blockSize, blockSize)
#             pygame.draw.rect(SCREEN, WHITE, rect, 1)

class EulerGrid():
    def __init__(self, cellSize):
        self.cellSize = cellSize
        self.numCells = math.ceil(WINDOW_HEIGHT/self.cellSize)
        self.xvgrid = np.zeros((self.numCells, self.numCells+1))
        self.yvgrid = np.zeros((self.numCells+1, self.numCells))
        self.gravity = 0
        self.density = 1
        self.iterations = 1
        self.preasures = np.zeros((self.numCells, self.numCells))
        self.walls = np.zeros((self.numCells, self.numCells))
        self.walls[1:self.numCells-1, 1:self.numCells-1] = 1
        self.flow = np.zeros((self.numCells, self.numCells))
        self.flow[self.numCells//2:self.numCells//2+5, 0] = 1
    def draw(self):
        preasures = self.preasures
        preasures = (preasures-np.min(preasures))/(np.max(preasures)-np.min(preasures))
        for i, x in enumerate(range(0, WINDOW_WIDTH, self.cellSize)):
            for j, y in enumerate(range(0, WINDOW_HEIGHT, self.cellSize)):
                rect = pygame.Rect(x, y, self.cellSize, self.cellSize)
                pygame.draw.rect(SCREEN, [255*preasures[j, i]]*3, rect)
                #pygame.draw.rect(SCREEN, WHITE, rect, 1)
    
    def updateVel(self, dt):
        self.yvgrid += dt*self.gravity
        self.xvgrid[self.numCells//2:self.numCells//2+5, 3] += 500
    def divergence(self, dt):
        self.preasures[:, :] = 0
        for n in range(self.iterations):
            for i in range(self.numCells):
                for j in range(self.numCells):
                    if self.walls[i, j] == 0:
                        self.xvgrid[i, j] = 0
                        self.xvgrid[i, j+1] = 0
                        self.yvgrid[i, j] = 0
                        self.yvgrid[i+1, j] = 0
                        continue
                    d = -self.xvgrid[i, j]+self.xvgrid[i, j+1]+self.yvgrid[i, j]-self.yvgrid[i+1, j]
                    s = self.walls[i-1, j]+self.walls[i+1, j]+self.walls[i, j-1]+self.walls[i, j+1]
                    #print("yvel: ", self.yvgrid[-4, j])
                    d = d*1.9
                    self.xvgrid[i, j] += d*self.walls[i, j-1]/s
                    self.xvgrid[i, j+1] -= d*self.walls[i, j+1]/s
                    self.yvgrid[i, j] -= d*self.walls[i-1, j]/s
                    self.yvgrid[i+1, j] += d*self.walls[i+1, j]/s
                    self.preasures[i, j] += d/s*(self.density*self.cellSize)/dt
        print(self.preasures)
    def advection(self, dt):
        aux_x = np.copy(self.xvgrid)
        aux_y = np.copy(self.yvgrid)
        #X component
        i, j = self.xvgrid.shape[0], self.xvgrid.shape[1]
        for y in range(i):
            for x in range(1, j-1):
                x_pos = x*self.cellSize
                y_pos = y*self.cellSize + self.cellSize/2
                v = (self.yvgrid[y, x-1]+self.yvgrid[y, x]+self.yvgrid[y+1, x-1]+self.yvgrid[y+1, x])/4
                x_pos -= self.xvgrid[y, x]*dt
                y_pos -= v*dt
                x_pos = x_pos/self.cellSize
                y_pos = y_pos/self.cellSize
                x_index = round(x_pos)
                y_index = math.floor(y_pos)
                aux_x[x, y] = self.xvgrid[x, y]
        self.xvgrid = aux_x
        i, j = self.yvgrid.shape[0], self.yvgrid.shape[1]
        for y in range(1, i-1):
            for x in range(j):
                x_pos = x*self.cellSize + self.cellSize/2
                y_pos = y*self.cellSize
                u = (self.xvgrid[y-1, x]+self.xvgrid[y, x]+self.xvgrid[y-1, x+1]+self.xvgrid[y, x+1])/4
                x_pos -= self.yvgrid[y, x]*dt
                y_pos -= v*dt
                x_pos = x_pos/self.cellSize
                y_pos = y_pos/self.cellSize
                x_index = math.floor(x_pos)
                y_index = round(y_pos)
                aux_y[x, y] = self.yvgrid[x, y]
        self.yvgrid = aux_y


    # dx = (x_pos-x_index+0.5)*self.cellSize
    # dy = y_pos - (y_index+1)
    # w00 = 1 - dx/self.cellSize
    # w01 = dx/self.cellSize
    # w10 = 1 - dy/self.cellSize
    # w11 = dy/self.cellSize
    # v = w00*w10*self.yvgrid[y_index+1, x_index-1] + w01*w10*self.yvgrid[y_index+1, x_index] + w01*w11*self.yvgrid[y_index, x_index-1] + w00*w11*self.yvgrid[y_index, x_index]

                





if __name__ == "__main__":
    main()