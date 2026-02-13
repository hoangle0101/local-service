import { Injectable, CanActivate, ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { PrismaService } from '../../prisma/prisma.service';
import { ROLES_KEY } from '../decorators/roles.decorator';

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(
    private reflector: Reflector,
    private prisma: PrismaService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const requiredRoles = this.reflector.getAllAndOverride<string[]>(ROLES_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    
    console.log('[RolesGuard] Required roles:', requiredRoles);
    
    if (!requiredRoles) {
      return true;
    }
    
    const { user } = context.switchToHttp().getRequest();
    
    console.log('[RolesGuard] User from request:', user);
    
    if (!user || !user.userId) {
      console.log('[RolesGuard] No user or userId found - DENIED');
      return false;
    }
    
    // Get user roles from database
    const userRoles = await this.prisma.userRole.findMany({
      where: { userId: BigInt(user.userId) },
      include: { role: true },
    });
    
    console.log('[RolesGuard] User roles from DB:', userRoles.map(ur => ur.role.name));
    
    const roleNames = userRoles.map((ur) => ur.role.name);
    
    // Check if user has any of the required roles
    const hasRole = requiredRoles.some((role) => roleNames.includes(role));
    console.log('[RolesGuard] Has required role:', hasRole);
    
    return hasRole;
  }
}
